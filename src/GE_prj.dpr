program GE_prj;

uses
  Forms,
  GE_Main in 'GE_Main.pas' {Form1},
  GE_Layout in 'GE_Layout.pas',
  GE_ColorOPS in 'GE_ColorOPS.pas',
  GE_4SS in 'GE_4SS.pas',
  GE_WS in 'GE_WS.pas',
  GE_MORPHO in 'GE_MORPHO.pas',
  GE_BLOCK_SG in 'GE_BLOCK_SG.pas',
  GE_Max_Tree in 'GE_Max_Tree.pas',
  GE_FastWS in 'GE_FastWS.pas',
  GE_ADAPT_THRESHOLD in 'GE_ADAPT_THRESHOLD.pas',
  GE_LABELING in 'GE_LABELING.pas',
  PixelQuenue in 'PixelQuenue.pas',
  GE_FDistance in 'GE_FDistance.pas',
  StdImageProcessing in 'StdImageProcessing.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
