module SmallestGrammar;

import std.stdio;
import std.conv;
import std.string;

import straight_line_grammar;
import greedy_grammar_reducer;

int main()
{
   while (true)
   {
      writeln("Enter a string: \n");

      auto s = readln();
      s = s.strip();
      auto g = new StraightLineGrammar!(char, ulong)(to!(char[])(s));
      auto reducer = new LeftMostPackedReducer!(char, ulong)(g);
      reducer.reduceGrammar();
      double sSize = s.length;
      auto size = g.grammarSize();
      double compressionRatio = sSize / size;
      writeln(g.toPrettyString());
      writeln("Compression ratio:", compressionRatio);
   }
   return 0;
}

