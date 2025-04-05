module grammar_substring_trie;

import std.format : format;
import std.conv : to;

struct GrammarSubstringLocation(Enc)
{
   Enc var;
   Enc start;
   Enc end;

   this(Enc var, Enc start, Enc end)
   {
      this.var = var;
      this.start = start;
      this.end = end;
   }

   string toString() const
   {
      return format("(%s,%s,%s)", var, start, end);
   }
}

struct SubstringLocation(Enc)
{
   Enc start, end;

   this(Enc start, Enc end)
   {
      this.start = start;
      this.end = end;
   }

   string toString() const
   {
      return format("(%s,%s)", start, end);
   }
}

struct GrammarSubstringWithItsLocations(Enc)
{
   Enc[] substring;
   SubstringLocation!Enc[][Enc] locationsByVar;

   this(Enc[] substring, const(GrammarSubstringLocation!Enc)[] locations)
   {
      this.substring = substring;

      foreach(loc; locations)
      {
         if (loc.var !in locationsByVar)
            locationsByVar[loc.var] = [];

         locationsByVar[loc.var] ~= SubstringLocation!Enc(loc.start, loc.end);
      }
   }

   string toString() const
   {
      return format("%s:%s", substring, locationsByVar);
   }
}

class GrammarSubstringTrie(Enc)
{
public:
   bool isEmpty() const 
   {
      return substrings.length == 0 && trie.length == 0;
   }

   bool opBinaryRight(string op="in")(Enc[] s) const
   {
      if (s[0] !in trie)
         return false;
      if (s.length == 1)
         return true;
      return s[1..$] in trie[s[0]];
   }

   void addSubstringLocation(const(Enc)[] substr, Enc var, Enc start, Enc end)
   {
      auto node = this;

      foreach (c; substr)
      {
         if (c !in node.trie)
         {
            node.trie[c] = new GrammarSubstringTrie();
         }

         node = node.trie[c];
      }

      node.substrings ~= GrammarSubstringLocation!Enc(var, start, end);
   }

   GrammarSubstringLocation!Enc[] listSubstringLocations() const
   {
      GrammarSubstringLocation!Enc[] list;

      if (substrings.length > 0)
         list ~= substrings;

      foreach (T; trie)
         list ~= T.listSubstringLocations();         

      return list;
   }

   GrammarSubstringWithItsLocations!Enc[] listSubstringsWithTheirLocations() const
   {
      GrammarSubstringWithItsLocations!Enc[] list;
      Enc[] prefix;        // The empty string
      listSubstringsWithTheirLocations(prefix, list);
      return list;
   }

   void filterOutIrreducibles() {
      filterOutIrreducibles(0);
   }

   Enc[][] listEncodedSubstrings() const
   {
      Enc[][] list;
      Enc[] prefix;     // The empty string
      listEncodedSubstrings(prefix, list);
      return list;
   }

   override string toString() const
   {
      return to!string(listEncodedSubstrings());
   }

private:
   // A reducible is a substring with length >= 2 that occurs at least twice disjointly within the grammar rhs's
   void filterOutIrreducibles(Enc length = 0)
   {
      if (length <= 1)
      {
         substrings = null;
      }
      else // This strings length is >= 2 and possibly reducibly occuring
      {               
         if (substrings.length > 0)    // Yes, it could be empty
         {
            bool reducible = false;
            auto s = substrings[0];       // Assumes we searched for substrings in a left-to-right order

            for (Enc j = 1; j < substrings.length; j++)
            {
               auto t = substrings[j];   

               if (t.var != s.var)
               {
                  reducible = true;
                  break;      // This substring is reducible
               }
               else if (t.start >= s.end)    // t, s occur disjointly within their (same) var's rule
               {
                  reducible = true;
                  break;
               }
            }

            if (! reducible)
               substrings = null;
         }
      }

      // Now recurse into the trie structure, incrementing length
      foreach (enc; trie.keys)
      {
         auto T = trie[enc];
         T.filterOutIrreducibles(length + 1);
         
         if (T.isEmpty())
            trie.remove(enc);       // Prune the tree if this subtree is empty
      }
   }

   void listEncodedSubstrings(Enc[] prefix, ref Enc[][] list) const
   {
      if (substrings.length > 0)    // If the this node records a string of interest
         list ~= prefix;

      foreach (enc; trie.keys)
         trie[enc].listEncodedSubstrings(prefix ~ enc, list);
   }

   void listSubstringsWithTheirLocations(Enc[] prefix, ref GrammarSubstringWithItsLocations!Enc[] list) const
   {
      if (substrings.length > 0)
         list ~= GrammarSubstringWithItsLocations!Enc(prefix, substrings);

      foreach (enc; trie.keys)
         trie[enc].listSubstringsWithTheirLocations(prefix ~ enc, list);
   }

   GrammarSubstringTrie[Enc] trie;
   GrammarSubstringLocation!Enc[] substrings;
}