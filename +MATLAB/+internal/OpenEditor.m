function OpenEditor(file)
if isempty(matlab.desktop.editor.Document.openEditor(file))
	TempFile=tempname;
	copyfile(file,TempFile,'f');
	matlab.desktop.editor.Document.openEditor(TempFile).saveAs(file);
	delete(TempFile);
end