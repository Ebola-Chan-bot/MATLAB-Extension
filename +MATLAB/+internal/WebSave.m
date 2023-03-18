function fileFromURL = WebSave(filename,url)
try
	fileFromURL = websave(filename,url);
catch ME
	if ME.identifier=="MATLAB:webservices:Timeout"
		fileFromURL = websave(filename,replace(url,'www.mathworks.com','ww2.mathworks.cn'));
	else
		ME.rethrow;
	end
end