module greedy_grammar_reducer;

import std.algorithm.mutation : remove;
import std.array : replace;
import std.algorithm.comparison : max;
import std.algorithm.sorting : sort;
import straight_line_grammar;
import grammar_substring_trie;

// TODO debug remove
import std.stdio;

abstract class GreedyGrammarReducer(Alpha, Enc)
{
public:
   this(StraightLineGrammar!(Alpha,Enc) grammar)
   {
      this.grammar = grammar;
   }

   abstract void reduceGrammar();

protected:
   StraightLineGrammar!(Alpha,Enc) grammar;
}


class LeftMostPackedReducer(Alpha, Enc) : GreedyGrammarReducer!(Alpha,Enc)
{
public:
   this(StraightLineGrammar!(Alpha,Enc) grammar)
   {
      super(grammar);
   }

   override void reduceGrammar()
   {
      auto reducibles = grammar.reduciblesTrie();
      
      
      while (! reducibles.isEmpty()) 
      {
         auto substrLocs = reducibles.listSubstringsWithTheirLocations();
         GrammarSubstringWithItsLocations!Enc greedyMax;
         Enc maxLength = 0;
         
         // Find in whatever order given (deterministic), a reducible of maximum length
         foreach (loc; substrLocs)
         {
            if (loc.substring.length > maxLength)
            {
               maxLength = loc.substring.length;
               greedyMax = loc;
            }
         }

         makeLeftMostPackedDisjointLocations(greedyMax);

         auto A = grammar.nextUnusedVar();
         
         // Replace each occurence of the substring within the main grammar with an A
         
         foreach (var; greedyMax.locationsByVar.keys)
         {
            auto locations = greedyMax.locationsByVar[var];
            Enc[] rhs = grammar[var];
            
            // Need to loop through in reverse to preserve remaining start/end's
            for (Enc j = locations.length; j > 0; j--)
            {
               auto loc = locations[j-1];
               rhs = rhs[0..loc.start] ~ A ~ rhs[loc.end..$];
            }

            grammar[var] = rhs;
         }

         // Create a new rule in the main grammar:
         grammar[A] = greedyMax.substring;

         // Repeat the process recursively on the further-reduced grammar:
         reducibles = grammar.reduciblesTrie();         
      }
   }

protected:
   struct CompressedSubgrammar
   {
      GrammarSubstringWithItsLocations!Enc substrLoc;    // Location within the main grammar
      StraightLineGrammar!(Alpha,Enc) subgrammar; 
      double compressionRatio;
      Enc totalSymbolCoverage;
   
      this(GrammarSubstringWithItsLocations!Enc substrLoc,
           StraightLineGrammar!(Alpha,Enc) subgrammar,
           double compressionRatio, Enc totalSymbolCoverage)
      {
         this.substrLoc = substrLoc;
         this.subgrammar = subgrammar;
         this.compressionRatio = compressionRatio;
         this.totalSymbolCoverage = totalSymbolCoverage;
      }
   }


   Enc maxNumberOfDisjointLocations(GrammarSubstringWithItsLocations!Enc substrLoc)
   {
      Enc disjointCount = 0;

      foreach (var; substrLoc.locationsByVar.keys)
      {
         auto locations = substrLoc.locationsByVar[var];
         auto previousLoc = locations[0];
         disjointCount ++;

         // Left-most packing for self-overlapping substrings
         for (Enc i = 1; i < locations.length; i++)
         {
            if (locations[i].start >= previousLoc.end)
            {
               disjointCount ++;
               previousLoc = locations[i];
            }
         }
      }

      return disjointCount;
   }

   void makeLeftMostPackedDisjointLocations(ref GrammarSubstringWithItsLocations!Enc substrLoc)
   {
      foreach (var; substrLoc.locationsByVar.keys)
      {
         auto locations = substrLoc.locationsByVar[var];
         auto previousLoc = locations[0];
         Enc[] indicesToDrop;

         for (Enc i = 1; i < locations.length; i++)
         {
            if (locations[i].start < previousLoc.end)
               indicesToDrop ~= i;
            else
               previousLoc = locations[i];
         }
         
         Enc j = 0;
         foreach (i; indicesToDrop)
         {
            locations = locations.remove(i - j);
            j ++;
         }
         
         substrLoc.locationsByVar[var] = locations;
      }
   }
}