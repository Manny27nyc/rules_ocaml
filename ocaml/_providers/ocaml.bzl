OcamlProvider = provider(
    doc = "OCaml module provider.",
    fields = {
        "inputs"             : "file depset",
        "linkargs"             : "file depset",
        "paths"             : "string depset",

        "files"             : "file depset",
        "archives"          : "file depset",
        "archive_deps"       : "file depset of archive deps",
        "ppx_codeps"      : "file depset",
        "ppx_codep_paths" : "string depset",
        "cc_deps"           : "dictionary depset",
        "ns_resolver"       : "single target",
    }
)

OcamlArchiveProvider = provider(
    doc = """OCaml archive provider.

Produced only by ocaml_archive, ocaml_ns_archive, ocaml_import.  Archive files are delivered in DefaultInfo; this provider holds deps of the archive, to serve as action inputs.
""",
    fields = {
        "files": "file depset of archive's deps",
        "paths": "string depset"
    }
)

# OcamlNsResolverMarker = provider(doc = "OCaml NsResolver Marker provider.")
OcamlNsResolverProvider = provider(
    doc = "OCaml NS Resolver provider.",
    fields = {
        "files"   : "Depset, instead of DefaultInfo.files",
        "paths":    "Depset of paths for -I params",
        "submodules": "String list of submodules in this ns",
        "resolver_file": "file",
        "resolver": "Name of resolver module",
        "prefixes": "List of alias prefix segs",
    }
)

OcamlSignatureProvider = provider(
    doc = "OCaml interface provider.",
    fields = {
        # "deps": "sig deps",

        "mli": ".mli input file",
        "cmi": ".cmi output file",
        # "module_links":    "Depset of module files to be linked by executable or archive rules.",
        # "archive_links":    "Depset of archive files to be linked by executable or archive rules.",
        # "paths":    "Depset of paths for -I params",
        # "depgraph": "Depset containing transitive closure of deps",
        # "archived_modules": "Depset containing archive contents"
    }
    # fields = module_fields
    # {
    #     # "ns_module": "Name of ns module (string)",
    #     "paths"    : "Depset of search path strings",
    #     "resolvers": "Depset of resolver module names",
    #     "deps_opam" : "Depset of OPAM package names"

    #     # "payload": "An [OcamlInterfacePayload](#ocamlinterfacepayload) structure.",
    #     # "deps"   : "An [OcamlDepsetProvider](#ocamldepsetprovider)."
    # }
)

OcamlArchiveMarker    = provider(doc = "OCaml Archive Marker provider.")
OcamlExecutableMarker = provider(doc = "OCaml Executable Marker provider.")
OcamlImportMarker    = provider(doc = "OCaml Library Marker provider.")
OcamlLibraryMarker   = provider(doc = "OCaml Library Marker provider.")
OcamlModuleMarker    = provider(doc = "OCaml Module Marker provider.")
OcamlNsMarker        = provider(doc = "OCaml Namespace Marker provider.")
OcamlSignatureMarker = provider(doc = "OCaml Signature Marker provider.")
OcamlTestMarker      = provider(doc = "OCaml Test Marker provider.")
