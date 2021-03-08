# Prune Juice

Prune unused Haskell dependencies from a Stack/Hpack project. Uses `hpack` to parse the project `package.yaml` files,
and `ghc-pkg` to load the `exposed-modules` fields of all the direct dependencies of the packages. Parses imports of
each source file, compares against the exposed modules, and errors if any dependency listed in `package.yaml` is never
imported by a source file.

## Usage

```bash
$ stack install
$ prune-juice --help
Usage: prune-juice [--stack-yaml-file STACK_YAML_FILE] [--package PACKAGE]
  Prune a Stack project's dependencies

Available options:
  -h,--help                Show this help text
  --stack-yaml-file STACK_YAML_FILE
                           Location of stack.yaml (default: "stack.yaml")
  --package PACKAGE        Package name(s)
```

## Improvements

### Performance

It's pretty slow, especially for big projects.

* Load exposed-modules once, instead of doing it for each package
* Fold over the import lists, removing module names and dependencies that have been used

## Testing and Availability

* Get it on Hackage
* Get it on Stackage
