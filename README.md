## Patches and scripts for running sommelier on Chrome OS developer shell

### Contents
- `platform2/`: Git submodule, linked to `platform2` repository (contain source code of `sommelier`)
- `sommelier_src/`: Symbolic link to `platform2/vm_tools/sommelier` (source code of `sommelier`)
- `dpi_checker/`: Scripts for getting the system DPI from browser
- `patches/`: Patches for running sommelier on Chrome OS developer shell.
- `sommelier-wrapper`: Wrapper script for `sommelier` binary, will insert `--drm-device` to command line (necessary for enabling hardware acceleration)
- `sommelier.env`: Set environment variables for `sommelier`
- `sommelierd`: `sommelier` daemon manager
- `sommelierrc`: Executes by `sommelier` X11 daemon after `Xwayland` is ready, will set text DPI/cursor theme
