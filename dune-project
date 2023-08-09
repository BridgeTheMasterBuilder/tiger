(lang dune 3.7)

(using menhir 2.1)

(name tigerc)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name tigerc)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  ocaml
  dune
  (containers
   (>= 3.10))
  (containers-data
   (>= 3.10))
  (cmdliner
   (>= 1.1.1))
  (iter
   (>= 1.6))
  (ocamlgraph
   (>= 2.0.0)))
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
