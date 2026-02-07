function root = projectRoot()
%PROJECTROOT Return project root folder (EMSimLab).
thisFile = mfilename('fullpath');
bootDir = fileparts(thisFile);
srcDir = fileparts(bootDir);
root = fileparts(srcDir);
end
