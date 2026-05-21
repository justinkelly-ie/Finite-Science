// Chapter-based numbering for books with appendix support
#let equation-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "(A.1)" } else { "(1.1)" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let callout-numbering = it => {
  let pattern = if state("appendix-state", none).get() != none { "A.1" } else { "1.1" }
  numbering(pattern, counter(heading).get().first(), it)
}
#let subfloat-numbering(n-super, subfloat-idx) = {
  let chapter = counter(heading).get().first()
  let pattern = if state("appendix-state", none).get() != none { "A.1a" } else { "1.1a" }
  numbering(pattern, chapter, n-super, subfloat-idx)
}
// Theorem configuration for theorion
// Chapter-based numbering (H1 = chapters)
#let theorem-inherited-levels = 1

// Appendix-aware theorem numbering
#let theorem-numbering(loc) = {
  if state("appendix-state", none).at(loc) != none { "A.1" } else { "1.1" }
}

// Theorem render function
// Note: brand-color is not available at this point in template processing
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  block(
    width: 100%,
    inset: (left: 1em),
    stroke: (left: 2pt + black),
  )[
    #if full-title != "" and full-title != auto and full-title != none {
      strong[#full-title]
      linebreak()
    }
    #body
  ]
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))



#let article(
  title: none,
  subtitle: none,
  authors: none,
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  // Set document metadata for PDF accessibility
  set document(title: title, keywords: keywords)
  set document(
    author: authors.map(author => content-to-string(author.name)).join(", ", last: " & "),
  ) if authors != none and authors != ()
  set par(
    justify: true,
    leading: linestretch * 0.65em
  )
  set text(lang: lang,
           region: region,
           size: fontsize)
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  set heading(numbering: sectionnumbering)

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      text(this)
    }
   }

  let has-title-block = title != none or (authors != none and authors != ()) or date != none or abstract != none
  if has-title-block {
    place(
      top,
      float: true,
      scope: "parent",
      clearance: 4mm,
      block(below: 1em, width: 100%)[

        #if title != none {
          align(center, block(inset: 2em)[
            #set par(leading: heading-line-height) if heading-line-height != none
            #set text(font: heading-family) if heading-family != none
            #set text(weight: heading-weight)
            #set text(style: heading-style) if heading-style != "normal"
            #set text(fill: heading-color) if heading-color != black

            #text(size: title-size)[#title #if thanks != none {
              footnote(thanks, numbering: "*")
              counter(footnote).update(n => n - 1)
            }]
            #(if subtitle != none {
              parbreak()
              text(size: subtitle-size)[#subtitle]
            })
          ])
        }

        #if authors != none and authors != () {
          let count = authors.len()
          let ncols = calc.min(count, 3)
          grid(
            columns: (1fr,) * ncols,
            row-gutter: 1.5em,
            ..authors.map(author =>
                align(center)[
                  #author.name \
                  #author.affiliation \
                  #author.email
                ]
            )
          )
        }

        #if date != none {
          align(center)[#block(inset: 1em)[
            #date
          ]]
        }

        #if abstract != none {
          block(inset: 2em)[
          #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
          ]
        }
      ]
    )
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  doc
}

#set table(
  inset: 6pt,
  stroke: none
)
#import "@preview/fontawesome:0.5.0": *
#let brand-color = (
  primary: rgb("#f36619")
)
#let brand-color-background = (
  primary: brand-color.primary.lighten(85%)
)
#let brand-logo = (:)
#show link: set text(fill: rgb("#f36619"), )

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)
// Logo is handled by orange-book's cover page, not as a page background
// NOTE: marginalia.setup is called in typst-show.typ AFTER book.with()
// to ensure marginalia's margins override the book format's default margins
#import "@preview/orange-book:0.7.1": book, part, chapter, appendices

#show: book.with(
  title: [YAQT],
  subtitle: [Yet Another Quantum Theory],
  author: "Justin Kelly",
  cover: image("orange-book/background.svg"),
  image-index: image("orange-book/orange1.jpg"),
  main-color: brand-color.at("primary", default: blue),
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
  outline-depth: 3,
)


// Reset Quarto's custom figure counters at each chapter (level-1 heading).
// Orange-book only resets kind:image and kind:table, but Quarto uses custom kinds.
// This list is generated dynamically from crossref.categories.
#show heading.where(level: 1): it => {
  counter(figure.where(kind: "quarto-float-fig")).update(0)
  counter(figure.where(kind: "quarto-float-tbl")).update(0)
  counter(figure.where(kind: "quarto-float-lst")).update(0)
  counter(figure.where(kind: "quarto-callout-Note")).update(0)
  counter(figure.where(kind: "quarto-callout-Warning")).update(0)
  counter(figure.where(kind: "quarto-callout-Caution")).update(0)
  counter(figure.where(kind: "quarto-callout-Tip")).update(0)
  counter(figure.where(kind: "quarto-callout-Important")).update(0)
  counter(math.equation).update(0)
  it
}

#heading(level: 1, numbering: none)[Preface]
<preface>
#block[
#callout(
body: 
[
#strong[Chapter Intent:] This chapter describes Singletons (#NormalTok("Sing");), Pixels (#NormalTok("Pix");) and Maxels (#NormalTok("Maxel");)- foundational types in Wildbergers Box Aritmetic, these are defined as finite collections of Multisets (#NormalTok("MSet1");).

The primary focus of this library is verifying structural mathematical properties (e.g., reflexivity, transitivity, symmetry) of these objects using the dependently typed programming language Idris 2 @brady2021idris.

]
, 
title: 
[
Chapter Summary
]
, 
background_color: 
brand-color-background.primary
, 
icon_color: 
brand-color.primary
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
Welcome to the #strong[Base module]! This chapter introduces the foundational data structures for the RCIT framework.

As discussed by Wildberger @wildberger2020box, we build upon the #NormalTok("MSet1"); structures to define our metric spaces. Let us look at the core imports and our first type, #NormalTok("Sing");.

#block[
#callout(
body: 
[
Notice how we use dependent types to guarantee that every #NormalTok("Sing"); contains exactly one #NormalTok("MSet1");.

]
, 
title: 
[
Note
]
, 
background_color: 
brand-color-background.primary
, 
icon_color: 
brand-color.primary
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
#heading(level: 3, numbering: none)[The Pixel and the Maxel]
<the-pixel-and-the-maxel>
A #NormalTok("Pix"); (Pixel) represents a directed edge between two #NormalTok("MSet1"); nodes. A #NormalTok("Maxel"); is an aggregation of multiple pixels, which can be thought of mathematically as an adjacency matrix or a multigraph.

Mathematically, if a pixel $p$ connects node $a$ to node $b$, its matrix representation would be: $ P_(i j) = cases(delim: "{", 1 & upright("if ") i = a upright(" and ") j = b, 0 & upright("otherwise")) $

#heading(level: 3, numbering: none)[Advanced Operations]
<advanced-operations>
When multiplying pixels together, we must ensure the destination node of the first pixel matches the source node of the second pixel. This is formally verified in Idris @brady2021idris.

Here we instantiate these concepts to test their behavior.

= Idris2 Base
<idris2-base>
Singletons are single mutisets. Pixels are pairs of singletons. Maxels are multisets of pixels.

== About
<about>
=== Types
<types>
This section demonstrates the basic instantiation and arithmetic of foundational data structures in the #NormalTok("Base"); module. These tests verify the correct behavior of singletons, pixels, maxels, and their operations before moving on to more complex property-based testing.

#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],));
=== Singletons
<singletons>
First, we will instantiate a singleton (#NormalTok("Sing");).

#Skylighting(([#FunctionTok("testSingletons");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("testSingletons ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" s ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkSing");#NormalTok(" (fromNat ");#DecValTok("5");#NormalTok(")");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Singleton: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show s");],));
=== Pixels
<pixels>
We now create directed edges (#NormalTok("Pix");) between basic numbers. A #NormalTok("Pix"); represents a directed connection from a source node to a target node.

#Skylighting(([#NormalTok("  ");#CommentTok("-- Create pixels (representing directed edges between numbers)");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" p1 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("1");#NormalTok(") (fromNat ");#DecValTok("2");#NormalTok(") ");#CommentTok("-- 1 -> 2");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" p2 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("2");#NormalTok(") (fromNat ");#DecValTok("3");#NormalTok(") ");#CommentTok("-- 2 -> 3");],
[#NormalTok("  ");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"p1: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show p1");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"p2: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show p2");],));
=== Maxel Arithmetic
<maxel-arithmetic>
A #NormalTok("Maxel"); aggregates multiple pixels. Here we verify both addition (which merges the subsets of pixels) and multiplication (which composes compatible edges). When we multiply maxels, a new pixel is formed only when the destination of an edge in the first maxel matches the source of an edge in the second.

#Skylighting(([#FunctionTok("testMaxelArithmetic");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("testMaxelArithmetic ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" p1 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("1");#NormalTok(") (fromNat ");#DecValTok("2");#NormalTok(")");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" p2 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("2");#NormalTok(") (fromNat ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" p3 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("3");#NormalTok(") (fromNat ");#DecValTok("4");#NormalTok(")");],
[#NormalTok("  ");],
[#NormalTok("  ");#CommentTok("-- Create sparse maxels");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" m1 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" [p1]");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" m2 ");#FunctionTok("=");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" [p2, p3]");],
[#NormalTok("  ");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"m1 + m2: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show (addMaxel m1 m2)");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"m1 * m2: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show (mulMaxel m1 m2)");],));
=== Vexel Dot Products
<vexel-dot-products>
We can simulate vector-like structures using "vexels" (vectors of pixels). A row vexel and a column vexel can be multiplied together to compute their dot product.

#Skylighting(([#FunctionTok("testVexelDotProduct");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("testVexelDotProduct ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" vRow ");#FunctionTok("=");#NormalTok(" rowVexel (fromNat ");#DecValTok("1");#NormalTok(") [fromNat ");#DecValTok("2");#NormalTok(", fromNat ");#DecValTok("3");#NormalTok("]");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" vCol ");#FunctionTok("=");#NormalTok(" colVexel (fromNat ");#DecValTok("4");#NormalTok(") [fromNat ");#DecValTok("2");#NormalTok(", fromNat ");#DecValTok("3");#NormalTok("]");],
[#NormalTok("  ");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Row Vexel: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show vRow");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Col Vexel: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show vCol");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Vexel Dot Product (vRow * vCol): \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show (mulMaxel vRow vCol)");],));
=== Diamond Poset Transitivity
<diamond-poset-transitivity>
Finally, we test the hardcoded #NormalTok("diamondMaxel");. By squaring it (multiplying it by itself), we verify that its structure correctly models mathematical transitivity.

#Skylighting(([#FunctionTok("testDiamondPoset");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("testDiamondPoset ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Diamond Maxel: \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show diamondMaxel");],
[#NormalTok("  putStrLn ");#FunctionTok("$");#NormalTok(" ");#StringTok("\"Diamond Maxel Squared (Transitivity): \"");#NormalTok(" ");#FunctionTok("++");#NormalTok(" show (mulMaxel diamondMaxel diamondMaxel)");],));
=== Executing the Tests
<executing-the-tests>
With all our test definitions in place, we can execute them sequentially in our #NormalTok("main"); function.

#Skylighting(([#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  testSingletons");],
[#NormalTok("  testMaxelArithmetic");],
[#NormalTok("  testVexelDotProduct");],
[#NormalTok("  testDiamondPoset");],));
== Properties
<properties>
=== Ordered Structures
<ordered-structures>
This module covers combinatorics.

#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Hedgehog");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Combinatorics");],
[],
[#FunctionTok("genNode");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("MSet1");],
[#NormalTok("genNode ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  n ");#OtherTok("<-");#NormalTok(" nat (linear ");#DecValTok("1");#NormalTok(" ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" fromNat n");],
[],
[#FunctionTok("genPix");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Pix");],
[#NormalTok("genPix ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  a ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  b ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" a b");],
[],
[#FunctionTok("genMaxel");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genMaxel ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#CommentTok("-- Small size to naturally hit property intersections");],
[#NormalTok("  pixels ");#OtherTok("<-");#NormalTok(" list (linear ");#DecValTok("0");#NormalTok(" ");#DecValTok("4");#NormalTok(") genPix");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" pixels");],
[],
[#FunctionTok("prop_T_plus_Y_implies_R");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_T_plus_Y_implies_R ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genMaxel");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" isTransitive m ");#FunctionTok("&&");#NormalTok(" isSymmetric m");],
[#NormalTok("     ");#KeywordTok("then");#NormalTok(" isReflexive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("     ");#KeywordTok("else");#NormalTok(" assert ");#DataTypeTok("True");#NormalTok(" ");],
[],
[#FunctionTok("genPoset");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genPoset ");#FunctionTok("=");#NormalTok(" pure diamondMaxel");],
[],
[#FunctionTok("prop_poset_properties");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_poset_properties ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#CommentTok("-- diamondMaxel is a strict poset");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genPoset");],
[#NormalTok("  isTransitive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isAntiSymmetric m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isIrreflexive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[],
[#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  success ");#OtherTok("<-");#NormalTok(" checkGroup ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkGroup");#NormalTok(" ");#StringTok("\"Ordered Structures\"");],
[#NormalTok("    [ (");#StringTok("\"prop_T_plus_Y_implies_R\"");#NormalTok(", prop_T_plus_Y_implies_R)");],
[#NormalTok("    , (");#StringTok("\"prop_poset_properties\"");#NormalTok(", prop_poset_properties)");],
[#NormalTok("    ]");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" success");],
[#NormalTok("    ");#KeywordTok("then");#NormalTok(" putStrLn ");#StringTok("\"SUCCESS\"");],
[#NormalTok("    ");#KeywordTok("else");#NormalTok(" putStrLn ");#StringTok("\"FAILURE\"");],));
=== Graphs
<graphs>
#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Hedgehog");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Combinatorics");],
[],
[#FunctionTok("genNode");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("MSet1");],
[#NormalTok("genNode ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  n ");#OtherTok("<-");#NormalTok(" nat (linear ");#DecValTok("1");#NormalTok(" ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" fromNat n");],
[],
[#FunctionTok("genPix");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Pix");],
[#NormalTok("genPix ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  a ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  b ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" a b");],
[],
[#FunctionTok("genMaxel");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genMaxel ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  pixels ");#OtherTok("<-");#NormalTok(" list (linear ");#DecValTok("0");#NormalTok(" ");#DecValTok("4");#NormalTok(") genPix");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" pixels");],
[],
[#FunctionTok("prop_undirected_symmetric");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_undirected_symmetric ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genMaxel");],
[#NormalTok("  ");#CommentTok("-- M + M^T is always symmetric!");],
[#NormalTok("  ");#KeywordTok("let");#NormalTok(" undirected ");#FunctionTok("=");#NormalTok(" addMaxel m (transposeMaxel m)");],
[#NormalTok("  isSymmetric undirected ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[],
[#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  success ");#OtherTok("<-");#NormalTok(" checkGroup ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkGroup");#NormalTok(" ");#StringTok("\"Graphs\"");],
[#NormalTok("    [ (");#StringTok("\"prop_undirected_symmetric\"");#NormalTok(", prop_undirected_symmetric) ]");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" success ");#KeywordTok("then");#NormalTok(" putStrLn ");#StringTok("\"SUCCESS\"");#NormalTok(" ");#KeywordTok("else");#NormalTok(" putStrLn ");#StringTok("\"FAILURE\"");],));
=== Equivalence Relations
<equivalence-relations>
#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Hedgehog");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Combinatorics");],
[],
[#FunctionTok("genNode");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("MSet1");],
[#NormalTok("genNode ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  n ");#OtherTok("<-");#NormalTok(" nat (linear ");#DecValTok("1");#NormalTok(" ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" fromNat n");],
[],
[#CommentTok("-- A complete graph (clique) over a set of nodes is always an equivalence relation");],
[#FunctionTok("genClique");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genClique ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  nodes ");#OtherTok("<-");#NormalTok(" list (linear ");#DecValTok("1");#NormalTok(" ");#DecValTok("3");#NormalTok(") genNode");],
[#NormalTok("  ");#CommentTok("-- Generate every possible a->b pair");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" [ ");#DataTypeTok("MkPix");#NormalTok(" a b ");#FunctionTok("|");#NormalTok(" a ");#OtherTok("<-");#NormalTok(" nodes, b ");#OtherTok("<-");#NormalTok(" nodes ]");],
[],
[#FunctionTok("prop_clique_is_equivalence");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_clique_is_equivalence ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genClique");],
[#NormalTok("  isReflexive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isSymmetric m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isTransitive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[],
[#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  success ");#OtherTok("<-");#NormalTok(" checkGroup ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkGroup");#NormalTok(" ");#StringTok("\"Equivalence Relations\"");],
[#NormalTok("    [ (");#StringTok("\"prop_clique_is_equivalence\"");#NormalTok(", prop_clique_is_equivalence) ]");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" success ");#KeywordTok("then");#NormalTok(" putStrLn ");#StringTok("\"SUCCESS\"");#NormalTok(" ");#KeywordTok("else");#NormalTok(" putStrLn ");#StringTok("\"FAILURE\"");],));
=== Relations
<relations>
#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Hedgehog");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Combinatorics");],
[],
[#FunctionTok("genNode");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("MSet1");],
[#NormalTok("genNode ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  n ");#OtherTok("<-");#NormalTok(" nat (linear ");#DecValTok("1");#NormalTok(" ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" fromNat n");],
[],
[#FunctionTok("genPix");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Pix");],
[#NormalTok("genPix ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  a ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  b ");#OtherTok("<-");#NormalTok(" genNode");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkPix");#NormalTok(" a b");],
[],
[#FunctionTok("genMaxel");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genMaxel ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  pixels ");#OtherTok("<-");#NormalTok(" list (linear ");#DecValTok("0");#NormalTok(" ");#DecValTok("4");#NormalTok(") genPix");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" pixels");],
[],
[#FunctionTok("prop_transpose_involution");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_transpose_involution ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genMaxel");],
[#NormalTok("  ");#CommentTok("-- Any Maxel is a relation (directed multigraph)");],
[#NormalTok("  ");#CommentTok("-- The transpose of the transpose is the original maxel!");],
[#NormalTok("  transposeMaxel (transposeMaxel m) ");#FunctionTok("===");#NormalTok(" m");],
[],
[#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  success ");#OtherTok("<-");#NormalTok(" checkGroup ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkGroup");#NormalTok(" ");#StringTok("\"Relations\"");],
[#NormalTok("    [ (");#StringTok("\"prop_transpose_involution\"");#NormalTok(", prop_transpose_involution) ]");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" success ");#KeywordTok("then");#NormalTok(" putStrLn ");#StringTok("\"SUCCESS\"");#NormalTok(" ");#KeywordTok("else");#NormalTok(" putStrLn ");#StringTok("\"FAILURE\"");],));
=== Tournaments
<tournaments>
#Skylighting(([#KeywordTok("module");#NormalTok(" ");#DataTypeTok("Main");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Hedgehog");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("MSet1");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Base");],
[#KeywordTok("import");#NormalTok(" ");#DataTypeTok("Combinatorics");],
[],
[#FunctionTok("genTournament");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Gen");#NormalTok(" ");#DataTypeTok("Maxel");],
[#NormalTok("genTournament ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  ");#CommentTok("-- A simple hardcoded tournament on 3 nodes: 1->2, 2->3, 1->3");],
[#NormalTok("  pure ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkMaxel");#NormalTok(" [");],
[#NormalTok("      ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("1");#NormalTok(") (fromNat ");#DecValTok("2");#NormalTok("),");],
[#NormalTok("      ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("2");#NormalTok(") (fromNat ");#DecValTok("3");#NormalTok("),");],
[#NormalTok("      ");#DataTypeTok("MkPix");#NormalTok(" (fromNat ");#DecValTok("1");#NormalTok(") (fromNat ");#DecValTok("3");#NormalTok(")");],
[#NormalTok("    ]");],
[],
[#FunctionTok("prop_is_tournament");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("Property");],
[#NormalTok("prop_is_tournament ");#FunctionTok("=");#NormalTok(" property ");#FunctionTok("$");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  m ");#OtherTok("<-");#NormalTok(" forAll genTournament");],
[#NormalTok("  isSet m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isIrreflexive m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isAntiSymmetric m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[#NormalTok("  isTotal m ");#FunctionTok("===");#NormalTok(" ");#DataTypeTok("True");],
[],
[#FunctionTok("main");#NormalTok(" ");#OtherTok(":");#NormalTok(" ");#DataTypeTok("IO");#NormalTok(" ()");],
[#NormalTok("main ");#FunctionTok("=");#NormalTok(" ");#KeywordTok("do");],
[#NormalTok("  success ");#OtherTok("<-");#NormalTok(" checkGroup ");#FunctionTok("$");#NormalTok(" ");#DataTypeTok("MkGroup");#NormalTok(" ");#StringTok("\"Tournaments\"");],
[#NormalTok("    [ (");#StringTok("\"prop_is_tournament\"");#NormalTok(", prop_is_tournament) ]");],
[#NormalTok("  ");#KeywordTok("if");#NormalTok(" success ");#KeywordTok("then");#NormalTok(" putStrLn ");#StringTok("\"SUCCESS\"");#NormalTok(" ");#KeywordTok("else");#NormalTok(" putStrLn ");#StringTok("\"FAILURE\"");],));



#bibliography(("references.bib"))

