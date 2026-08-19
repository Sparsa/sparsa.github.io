require 'rouge'

module Rouge
  module Lexers
    # A Lexer for the Lean theorem prover (Lean 4).
    #
    # Rouge's built-in `lean` lexer does not recognise Lean's rich Unicode
    # vocabulary (∀, ∘, ⟶, Greek letters, subscript digits, ...) and marks
    # them as error tokens, which renders them red. This lexer instead
    # handles those symbols and lets any unrecognised character fall back
    # to plain text rather than an error.
    class Lean < RegexLexer
      title 'Lean'
      desc 'The Lean theorem prover'
      tag 'lean'
      filenames '*.lean'
      mimetypes 'text/x-lean'

      KEYWORDS = %w[
        def theorem lemma axiom example abbrev opaque
        class structure inductive coinductive mutual instance
        namespace section end open export import prelude init
        variable variables parameter parameters
        where let in match with if then else
        fun forall lambda fun_fun do return
        by have show from exact intro intros apply rfl
        simp rw cases case constructor omega decide contradiction
        exfalso obtain exists use rec termination_by decreasing_by
        deriving extends macro syntax notation scoped
        infix infixl infixr postfix prefix attribute
        set_option local private protected noncomputable partial
        unsafe builtin initializer unchecked universe universes
        hide export run_cmd elab command pure bind
      ].freeze

      state :root do
        # whitespace (including newlines — otherwise they become error tokens)
        rule %r/\s+/, Text

        # comments
        rule %r{--!.*$}, Comment::Doc
        rule %r{--#.*$}, Comment
        rule %r{--.*$}, Comment::Single
        rule %r{/\*-!\s.*?\*/}m, Comment::Doc
        rule %r{/\*.*?\*/}m, Comment::Multiline

        # strings and char literals
        rule %r{"(?:[^"\\]|\\.)*"}, Str::Double
        rule %r{'(?:[^'\\]|\\.)'}, Str::Char

        # numbers
        rule %r{0[xX][0-9a-fA-F_]+}, Num::Hex
        rule %r{0[bB][01_]+}, Num::Bin
        rule %r{\d[\d_]*}, Num

        # keywords
        rule %r{\b(?:#{KEYWORDS.join('|')})\b}, Keyword
        rule %r{[∀∃λ]}, Keyword

        # identifiers (Unicode-aware: Greek letters, subscripts, primes)
        rule %r{[\p{L}_][\p{L}\p{N}\p{Mn}_'`]*}, Name

        # operators and unicode symbols
        rule %r{[-+*/%=&|^!<>=~$@?:.]+}, Operator
        rule %r{[→⟶↦⇒←↔∀∃∈∉⊢⊨∅∪∩⊓⊔≤≥≠]}, Operator

        # punctuation
        rule %r{[{}()\[\],;\\]}, Punctuation

        # anything else: plain text, never an error token
        rule %r/./, Text
      end
    end
  end
end