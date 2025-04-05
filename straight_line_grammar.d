module straight_line_grammar;

import std.conv : to;
import std.format : format;
import std.algorithm : max, min;
import grammar_substring_trie;

class StraightLineGrammar(Alpha, Enc)
{
public:
   this(Alpha[] s)
   {
      Enc enc = 0;
      Enc[] rhs;

      foreach (c; s)
      {
         if (!(c in alphaToEnc))
         {
            alphaToEnc[c] = enc;
            encToAlpha[enc] = c; 
            enc++;
         }

         rhs ~= alphaToEnc[c];
      }

      startVar = enc;
      nextAlpha = 'A';
      this[startVar] = rhs;
   }

   Enc nextUnusedVar() const 
   {
      return startVar + grammarRules.length;
   }

   Enc[] opIndex(Enc var) {
      return grammarRules[var];
   }

   void opIndexAssign(Enc[] rhs, Enc var)
   {
      grammarRules[var] = rhs;

      // Create a new Alpha for debug pretty printing (in standard ascii grammar format)
      if (var !in encToAlpha)
      {
         encToAlpha[var] = nextAlpha;
         alphaToEnc[nextAlpha] = var;
         nextAlpha ++;
      }
   }

   Alpha[] encodedStringToAlpha(const(Enc)[] encoded) const
   {
      Alpha[] alphaString;
      foreach (c; encoded)
      {
         alphaString ~= encToAlpha[c];
      }
      return alphaString;
   }

   Enc grammarSize() const
   {
      Enc size = 0;
      foreach (rhs; grammarRules)
         size += rhs.length;
      return size;
   }

   Enc[] variables() const
   {
      return grammarRules.keys;
   }

   // Warning: may return dupliacte Alpha[] substrings
   Alpha[][] listAlphaSubstrings(GrammarSubstringTrie!Enc trie=null) const
   {
      if (trie is null)
         trie = substringTrie();

      auto encList = trie.listEncodedSubstrings();
      Alpha[][] alphaList;

      foreach (enc; encList)
      {
         Alpha[] t;
         foreach (e; enc)
            t ~= encToAlpha[e];
         alphaList ~= t;
      }

      return alphaList;
   }

   string[] listSubstringsAs(T)(GrammarSubstringTrie!Enc trie=null) const
   {
      if (trie is null)
         trie = substringTrie();

      auto alphaList = listAlphaSubstrings(trie);
      T[] list;

      foreach (t; alphaList)
      {
         auto s = to!T(t);
         list ~= s;
      }

      return list;
   }

   string[] listReduciblesAs(T)() const
   {
      auto trie = reduciblesTrie();
      auto list = listSubstringsAs!T(trie);
      return list;
   }

   GrammarSubstringTrie!Enc substringTrie(Enc minLength=0) const
   {
      auto substrs = new GrammarSubstringTrie!Enc();
      
      foreach (A; grammarRules.keys)
      {
         auto rhs = grammarRules[A];

         for (Enc i=0; i < rhs.length - minLength + 1; i++)
         {
            for (Enc j=i+minLength; j < rhs.length + 1; j++)
            {
               auto t = rhs[i..j];
               substrs.addSubstringLocation(t, A, i, j);
            }
         }
      }

      return substrs;
   }

   GrammarSubstringTrie!Enc reduciblesTrie(Enc minLength=2) const
   {
      auto reducibles = new GrammarSubstringTrie!Enc();

      foreach (A; grammarRules.keys)
      {
         auto rhs = grammarRules[A];
         auto maxLength = rhs.length / 2;

         for (Enc i=0; i < rhs.length - minLength + 1; i++)
         {
            for (Enc j=i+minLength; j < min(rhs.length, i+maxLength) + 1; j++)
            {
               auto t = rhs[i..j];
               reducibles.addSubstringLocation(t, A, i, j);
            }
         }
      }

      // Once we have all possible substrings of interest, filter out what is not reducible
      reducibles.filterOutIrreducibles();
      return reducibles;
   }

   // For small examples only!
   string toPrettyString() const
   {
      string str = "";
      Enc[] orderedVars = [startVar];
      gatherVariablesInOrder(startVar, orderedVars);

      foreach (A; orderedVars)
      {
         auto var = to!string(encodedStringToAlpha([A]));
         auto rhs = to!string(encodedStringToAlpha(grammarRules[A]));
         str ~= format("%s -> %s\n", var, rhs);
      }

      return str;
   }

   override string toString() const
   {
      string res = "";
      res ~= to!string(encToAlpha);
      res ~= "\n";
      res ~= to!string(grammarRules);
      return res;
   }

private:
   // Left to right order within the start rule, depth first expansion
   void gatherVariablesInOrder(Enc startVar, ref Enc[] orderedVars, bool[Enc] varSet=null) const
   {
      auto rhs = grammarRules[startVar];
      
      foreach (A; rhs)
      {
         if (A in grammarRules)
         {
            if (A !in varSet)
            {
               varSet[A] = true;
               orderedVars ~= A;
               gatherVariablesInOrder(A, orderedVars, varSet);
            }
         }
      }
   }

   Enc[Alpha] alphaToEnc;
   Alpha[Enc] encToAlpha;
   Enc[][Enc] grammarRules;
   Enc startVar;
   Alpha nextAlpha;
}