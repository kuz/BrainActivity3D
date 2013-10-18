function mtlwrite(mtl,filename)
% Write a Material Template Library (MTL) file.
%
% Usage:
% mtlwrite(mtl,filename)
%
% - mtl:      Struct containing the material names
%             in the first level, and the material
%             features in the second level, as produced
%             by the accompanying mtlread function.
% - filename: File name of the MTL.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jul/2011
% http://brainder.org

% Get the list of material names
matname = fieldnames(mtl);

% Open for saving
fid = fopen(filename,'w');

% For each material
for m = 1:numel(matname),

    % Add its name
    fprintf(fid,'newmtl %s\n',matname{m});

    % Get the list of features of the current material
    mfeat = fieldnames(mtl.(matname{m}));
    
    % For each feature
    for f = 1:numel(mfeat),
        
        % Add its name
        fprintf(fid,'%s',mfeat{f});
        
        % Then add separately numeric and string fields
        if isnumeric(mtl.(matname{m}).(mfeat{f}))
            fprintf(fid,' %g',mtl.(matname{m}).(mfeat{f}));
            fprintf(fid,'\n');
        elseif ischar(mtl.(matname{m}).(mfeat{f})),
            fprintf(fid,' %s\n',mtl.(matname{m}).(mfeat{f}));
        end
    end
    
    % Add an EOL to separate each material for clarity
    fprintf(fid,'\n');
end

% That's it!
fclose(fid);
