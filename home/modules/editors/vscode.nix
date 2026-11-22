{ pkgs, ... }:
let
  # A selected Chinese-capable toolchain, rather than scheme-full. ctex's
  # Linux default uses Fandol; keep that font with the XeLaTeX packages.
  latex = pkgs.texliveSmall.withPackages (ps: with ps; [
    latexmk xetex ctex xecjk biblatex biber fandol
  ]);
  latexmkTool = name: engine: {
    inherit name;
    command = "${latex}/bin/latexmk";
    args = [
      "-synctex=1" "-interaction=nonstopmode" "-file-line-error"
      engine "-outdir=%OUTDIR%" "-auxdir=%AUXDIR%" "%DOC%"
    ];
  };
in
{
  # Extensions need executable toolchains, not just their language servers.
  # Java comes from the system JDK; Python and npm dependencies remain project
  # choices. The other compilers and the selected TeX stack live with VS Code.
  home.packages = with pkgs; [
    gcc cargo rustc rustfmt
    iverilog verible
    latex
  ];

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    # Only the display-language preference is migrated from ~/.vscode/argv.json.
    # Machine-specific crash-report identifiers and authentication are excluded.
    argvSettings.locale = "zh-cn";
    profiles.default = {
      userSettings = (builtins.fromJSON (builtins.readFile ../../vscode/settings.json)) // {
        "jdk.jdkhome" = pkgs.jdk.home;
        "latex-workshop.latex.recipe.default" = "latexmk (XeLaTeX)";
        "latex-workshop.latex.recipes" = [
          { name = "latexmk (XeLaTeX)"; tools = [ "xelatexmk" ]; }
          { name = "latexmk (pdfLaTeX)"; tools = [ "pdflatexmk" ]; }
        ];
        "latex-workshop.latex.tools" = [
          (latexmkTool "xelatexmk" "-xelatex")
          (latexmkTool "pdflatexmk" "-pdf")
        ];
      };
      keybindings = ../../vscode/keybindings.json;
      extensions = with pkgs.vscode-extensions; [
        anthropic.claude-code
        bierner.markdown-preview-github-styles
        catppuccin.catppuccin-vsc-icons
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        firefox-devtools.vscode-firefox-debug
        github.vscode-github-actions
        james-yu.latex-workshop
        ms-ceintl.vscode-language-pack-zh-hans
        ms-python.isort
        ms-python.python
        ms-python.vscode-pylance
        ms-python.vscode-python-envs
        ms-toolsai.jupyter
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-slideshow
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        ms-vscode.hexeditor
        ms-vscode.remote-explorer
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        mshr-h.veriloghdl
        myriad-dreamin.tinymist
        oracle.oracle-java
        rust-lang.rust-analyzer
        shd101wyy.markdown-preview-enhanced
        teabyii.ayu
        yzhang.markdown-all-in-one
      ];
    };
  };
}
