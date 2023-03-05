function OpenEditor(file)
if isempty(matlab.desktop.editor.Document.openEditor(file))
	[~,Filename,Extension]=fileparts(file);
	TempFile=fullfile(tempdir,strcat(Filename,Extension));
	copyfile(file,TempFile,'f');
	matlab.desktop.editor.Document.openEditor(TempFile).saveAs(file);
	delete(TempFile);
end