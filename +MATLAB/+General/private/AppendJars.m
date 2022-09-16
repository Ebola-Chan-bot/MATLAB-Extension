function Paths = AppendJars(Paths)
NumPaths=numel(Paths);
Jars=cell(NumPaths,1);
for P=1:NumPaths
    if isfolder(Paths(P))
        Jars{P}=string(System.IO.Directory.GetFiles(Paths(P),'*.jar'));
    end
end
Paths=[Paths Jars{:}];