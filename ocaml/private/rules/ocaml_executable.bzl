load("//ocaml/private:common.bzl",
     "OCAML_VERSION")
load("//ocaml/private/actions:ppx.bzl",
     "apply_ppx",
     "compile_new_srcs")
load("//ocaml/private/actions:ocaml.bzl",
     "ocaml_compile")
load("//ocaml/private/actions:batch.bzl", "copy_srcs_to_tmp")
load("//ocaml/private:providers.bzl",
     "OcamlArchiveProvider",
     "OcamlLibraryProvider",
     "OcamlModuleProvider",
     "OcamlSDK",
     "OpamPkgInfo",
     "PpxInfo")

load("//ocaml/private:deps.bzl", "get_all_deps")

load("//ocaml/private:utils.bzl",
     "get_opamroot",
     "get_sdkpath",
     "strip_ml_extension",
     "OCAML_FILETYPES",
     "OCAML_IMPL_FILETYPES",
     "OCAML_INTF_FILETYPES",
     "WARNING_FLAGS"
)

# def _ocaml_interface_impl(ctx):
#   ctx.actions.run_shell(
#       inputs = [ctx.file.src, ctx.executable._ocamlc],
#       outputs = [ctx.label.name + "mli"], # [ctx.outputs.mli],
#       progress_message = "Compiling interface file %s" % ctx.label,
#       mnemonic="OCamlc",
#       command = "%s -i -c %s > %s" % (ctx.executable._ocamlc.path, ctx.file.src.path, ctx.outputs.mli.path),
#   )

#   return struct(mli = ctx.outputs.mli.path)

# ocaml_interface = rule(
#     implementation = _ocaml_interface_impl,
#     attrs = dict(
#       _ocaml_tools_attrs,
#       src = attr.label(
#         allow_files = OCAML_FILETYPES,
#         # allow_single_file = True,
#         )
#     ),
#     # outputs = { "mli": "%{name}.mli" },
# )

################################################################
def _ocaml_executable_impl(ctx):

  debug = False
  # if (ctx.label.name == "vector_ffi_bindings.cm_"):
  #     debug = True

  # print("EXECUTABLE TARGET: %s" % ctx.label.name)

  mydeps = get_all_deps("ocaml_executable", ctx) # ctx.attr.deps)
  # print("ALL DEPS for %s" % ctx.label.name)
  # print(mydeps)

  env = {"OPAMROOT": get_opamroot(),
         "PATH": get_sdkpath(ctx)}

  # srcs = copy_srcs_to_tmp(ctx)

  tc = ctx.toolchains["@obazl_rules_ocaml//ocaml:toolchain"]

  if ctx.attr.exe_name:
    outfilename = ctx.attr.exe_name
    outbinary = ctx.actions.declare_file(outfilename)
  else:
    outfilename = ctx.label.name
    outbinary = ctx.actions.declare_file(outfilename)
  # we will wait to add the -o flag until after we compile the interface files

  args = ctx.actions.args()
  args.add("ocamlopt")
  args.add_all(ctx.attr.opts)

  lflags = " ".join(ctx.attr.linkopts) if ctx.attr.linkopts else ""
  args.add_all(ctx.attr.linkopts)

  ## deps are the same for all sources (.mli, .ml)
  ## we need to accumulate them so we can add them to the action inputs arg,
  ## in order to  register the dependency with Bazel.
  build_deps = []
  includes = []
  args.add("-linkpkg")  ## an ocamlfind parameter
  # print("OPAM_DEPS: %s" % mydeps.opam)
  # for dep in mydeps.opam.to_list():
  #   # print("OPAM DEP: %s" % dep)
  #   # for depdep in dep.to_list():
  #     # print("OPAM DEPDEP: %s" % depdep)
  #   args.add("-package", dep.pkg.to_list()[0].name)

  args.add_all([dep.pkg.to_list()[0].name for dep in mydeps.opam.to_list()], before_each="-package")
  args.add("-absname")

  # print("NOPAM_DEPS for {bin}: {deps}".format(bin=ctx.label.name, deps=mydeps.nopam))
  # for dep in mydeps.nopam.to_list():  # ctx.attr.deps:
  #   print("################ NOPAM_DEP ################ :\n\t\t %s" % dep)
  #   # if hasattr(dep, "clib"):
  #   #   build_deps = build_deps + dep.clib.files.to_list()

  #   #   ##FIXME:
  #   #   # args.add("-cclib", "-lrakia")

  #   if hasattr(dep, "cmxa"):    ## composited lib
  #     # print("ARCHIVE DEP: %s" % dep)
  #     build_deps.append(dep.cmxa)
  #     includes.append(dep.cmxa.dirname)

  #   if hasattr(dep, "cm"):    ## composited lib
  #     build_deps.append(dep.cm)
  #     includes.append(dep.cm.dirname)
  #     args.add(dep.cm)

  # for dep in mydeps.nopam.to_list():
  #   # print("NOPAM DEP: %s" % dep)
  #   if dep.basename.endswith(".cmx"):
  #     includes.append(dep.dirname)
  #     args.add(dep)
  #     build_deps.append(dep)
    # elif dep.basename.endswith(".cmxa"):
    #   includes.append(dep.dirname)
    #   args.add(dep)
    #   build_deps.append(dep)

  input_deps = []
  for dep in ctx.attr.deps:
    for g in dep[DefaultInfo].files.to_list():
        if g.basename.endswith(".cmx"):
            includes.append(g.dirname)
            args.add(g)
            build_deps.append(g)
        elif g.basename.endswith(".cmxa"):
            input_deps.append(g)
            args.add(g)
            build_deps.append(g)

  # for dep in ctx.attr.deps:
  #   # if OcamlArchiveProvider in dep:
  #   #   payload = dep[OcamlArchiveProvider].payload
  #   #   print("DEP OCAML ARCHIVE: %s" % payload)
  #   #   includes.append(payload.cmxa.dirname)
  #   #   args.add(payload.cmxa.basename)
  #   #   build_deps.append(payload.cmxa)
  #   if OcamlArchiveProvider in dep:
  #     # print("$$$$$$$$$$$$$$$$ OCamlArchiveProvider: %s" % dep)
  #     payload = dep[OcamlArchiveProvider].payload
  #     includes.append(payload.cmxa.dirname)
  #     args.add(payload.cmxa.basename)
  #     build_deps.append(payload.cmxa)
  #     for module in dep[OcamlArchiveProvider].deps.nopam.to_list():
  #       # print("LIBDEP: %s" % module)
  #       # for libModule in dep[OcamlArchiveProvider].payload.modules:
  #       if module.path.endswith(".cmx"):
  #         includes.append(module.dirname)

  #   elif OcamlModuleProvider in dep:
  #     payload = dep[OcamlModuleProvider].payload
  #     # print("DEP OCAML MODULE: %s" % payload)
  #     includes.append(payload.cm.dirname)
  #     args.add(payload.cm.basename)
  #     build_deps.append(payload.cm)
    # else:
    #   for g in dep[DefaultInfo].files.to_list():
    #     # print("    PATH: %s" % g.path)
    #     # exclude cmi deps, archives do not know what to do with them
    #     # if g.path.endswith(".cmi"):
    #     #   build_deps.append(g)
    #     includes.append(g.dirname)
    #     # if g.path.endswith(".cmx"):
    #     #   args.add(g)
    #     #   build_deps.append(g)
    #     # if g.path.endswith(".cmxa"):
    #     #   args.add(g)
    #     #   build_deps.append(g)

  cclib_deps = []
  for dep in ctx.attr.cc_deps.items():
    if debug:
        print("CCLIB DEP: ")
        print(dep)
    if dep[1] == "static":
        if debug:
            print("STATIC lib: %s:" % dep[0])
        for depfile in dep[0].files.to_list():
            if (depfile.extension == "a"):
                args.add(depfile)
                cclib_deps.append(depfile)
                includes.append(depfile.dirname)
    elif dep[1] == "dynamic":
        if debug:
            print("DYNAMIC lib: %s" % dep[0])
        for depfile in dep[0].files.to_list():
            print("DEPFILE: %s" % depfile)
            print("DEPFILE extension: %s" % depfile.extension)
            if (depfile.extension == "so"):
                libname = depfile.basename[:-3]
                print("LIBNAME: %s" % libname)
                libname = libname[3:]
                print("LIBNAME: %s" % libname)
                args.add("-ccopt", "-L" + depfile.dirname)
                args.add("-cclib", "-l" + libname)
                cclib_deps.append(depfile)
            elif (depfile.extension == "dylib"):
                libname = depfile.basename[:-6]
                libname = libname[3:]
                print("LIBNAME: %s:" % libname)
                args.add("-cclib", "-l" + libname)
                args.add("-ccopt", "-L" + depfile.dirname)
                cclib_deps.append(depfile)

  # cclib_deps = []
  # for dep in ctx.attr.cc_deps:
  #   # print("CCLIB DEP: %s" % dep)
  #   for depfile in dep.files.to_list():
  #     # print("CCLIB DEP FILE: %s" % depfile)
  #     includes.append(depfile.dirname)

  #     ##FIXME:  if linkstatic
  #     if depfile.extension == "a":
  #       cclib_deps.append(depfile)
  #       build_deps.append(depfile)
  #       args.add(depfile)
  #       ## -dllib is for bytecode only
  #       # args.add("-dllib", "lrakia")
  #       ## incredibly, starlark's rstrip function does not strip suffix strings. we have to hack it:
  #       # libname = depfile.basename.rstrip("a")
  #       # libname = libname.rstrip(".")
  #       # libname = libname[3:]
  #       # # args.add(depfile)
  #       # args.add("-ccopt", "-L" + depfile.dirname)
  #       # args.add("-cclib", "-l" + libname)
  #     if depfile.extension == "lo":
  #       libname = depfile.basename.rstrip("o")
  #       libname = libname.rstrip("l")
  #       libname = libname.rstrip(".")
  #       libname = libname[3:]
  #       args.add("-cclib", "-l" + libname)
  #       # cclib_deps.append(depfile)
  #     elif depfile.extension == "dylib":
  #       ## -dllib is for bytecode only
  #       # args.add("-dllib", "lrakia")
  #       ## incredibly, starlark's rstrip function does not strip suffix strings. we have to hack it:
  #       libname = depfile.basename.rstrip("dylib")
  #       libname = libname.rstrip(".")
  #       libname = libname[3:]
  #       args.add("-ccopt", "-L" + depfile.dirname)
  #       args.add("-cclib", "-l" + libname)
  #       # cclib_deps.append(depfile)
  #     elif depfile.extension == "so":
  #       libname = depfile.basename.rstrip("o")
  #       libname = libname.rstrip("s")
  #       libname = libname.rstrip(".")
  #       libname = libname[3:]
  #       args.add("-ccopt", "-L" + depfile.dirname)
  #       args.add("-cclib", "-l" + libname)
  #       # cclib_deps.append(depfile)
  #     #   libname = depfile.basename.rstrip(".dylib")
  #     #   libname = libname.lstrip("lib")
  #     #   args.add("-cclib", "-l" + libname)

  args.add_all(includes, before_each="-I", uniquify = True)

  # srcs_ml  = []
  # outs_cmx = []

  # for src in srcs: ## ctx.files.srcs:
  #   if src.path.endswith(".ml"):
  #     srcs_ml.append(src)
  #     args.add("-I", src.dirname)
  #     # register cmx outfile with Bazel
  #     # outfname = src.basename.rstrip(".ml") + ".cmx"
  #     # outf = ctx.actions.declare_file(outfname)
  #     # outs_cmx.append(outf)
  #   else:
  #     fail("Not an OCaml source file: %s" % src.path)

  # ## without this, the compiler may not be able to find the cmi files:
  # includes_mli = []
  # for src in srcs_mli:
  #   includes_mli.append(src.dirname)
  # args.add_all(includes_mli, before_each="-I", uniquify = True)

  # args.add_all(outs_cmi)

  # args.add_all(cclib_deps)

  args.add("-o", outbinary)

  if ctx.attr.strip_data_prefixes:
    myrunfiles = ctx.runfiles(
      files = ctx.files.data,
      symlinks = {dfile.basename : dfile for dfile in ctx.files.data}
    )
  else:
    myrunfiles = ctx.runfiles(
      files = ctx.files.data,
    )

  input_deps = input_deps + build_deps + cclib_deps #  srcs_ml + outs_cmi
  # print("BUILD DEPS: %s" % build_deps)

  # then compile implementation files and produce executable
  # if srcs_ml:
  ctx.actions.run(
    env = env,
    executable = tc.ocamlfind,
    arguments = [args],
    inputs = input_deps,
    outputs = [outbinary],
    # tools = build_deps,
      progress_message = "ocaml_executable({}): compiling implementations {}".format(
        ctx.label.name, ctx.attr.message
      )
  )

  return [DefaultInfo(executable = outbinary,
                      runfiles = myrunfiles)]

################################################################
ocaml_executable = rule(
  implementation = _ocaml_executable_impl,
  attrs = dict(
    exe_name = attr.string(),
    _sdkpath = attr.label(
      default = Label("@ocaml//:path")
    ),
    srcs = attr.label_list(
      allow_files = OCAML_FILETYPES
    ),
    # srcs_impl = attr.label_list(
    #   allow_files = OCAML_IMPL_FILETYPES
    # ),
    # srcs_intf = attr.label_list(
    #   allow_files = OCAML_INTF_FILETYPES
    # ),
    data = attr.label_list(
      allow_files = True,
      doc = "Data files used by this executable."
    ),
    strip_data_prefixes = attr.bool(
      doc = "Symlink each data file to the basename part in the runfiles root directory. E.g. test/foo.data -> foo.data.",
      default = False
    ),
    opts = attr.string_list(),
    copts = attr.string_list(),
    linkopts = attr.string_list(),
    preprocessor = attr.label(
      doc = "Preprocessor. Must be a single PPX executable.",
      allow_single_file = True,
      providers = [PpxInfo],
      executable = True,
      cfg = "exec",
    ),
    deps = attr.label_list(
      doc = "Dependencies. Do not include preprocessor (PPX) deps.",
      providers = [[OpamPkgInfo],
                   [OcamlArchiveProvider],
                   [OcamlLibraryProvider],
                   [OcamlModuleProvider],
                   [CcInfo]],
    ),
    cc_deps = attr.label_keyed_string_dict(
      doc = "C/C++ library dependencies",
      providers = [[CcInfo]]
    ),
    mode = attr.string(default = "native"), # or "bytecode"
    message = attr.string()
  ),
  executable = True,
  toolchains = ["@obazl_rules_ocaml//ocaml:toolchain"],
)
