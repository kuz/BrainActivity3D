function mtl = mtlread(varargin)
% Read a Material Template Library (MTL) file.
%
% Usage:
% mtl = mtlread(filename,matname)
%
% - filename: File name of the MTL.
% - matnames: [Optional] Material name(s) to be selected.
%             Use a cell array to select more than one.
% - mtl:      Struct containing the material names
%             in the first level, and the material
%             features in the second level.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jul/2011
% http://brainder.org

% Quick sanity check
if nargin < 1 || nargin > 2,
    error('Insufficient arguments.');
end

% Read the MTL file
fname = varargin{1};
fid = fopen(fname,'r');
tmp = fread(fid,Inf,'uint8=>char')';
fclose(fid);

% Break down lines and fields
tmp     = regexp(tmp,'\n+','split');
mtlcell = regexp(tmp,'\s+','split');

% Remove empties (likely to be only the last one)
for c = numel(mtlcell):-1:1,
    if isempty(mtlcell{c}),
        mtlcell(c) = [];
    end
end

% Loop over each cell to test the 1st word of the line
for c = 1:numel(mtlcell),
    mfeat = mtlcell{c}{1};
    switch mfeat,
        case {'#',''}
            % these are comments and empty lines only

        case 'newmtl'
            % If a new material, create an empty field for it
            matname = mtlcell{c}{2};
            mtl.(matname) = {};

        otherwise
            % For the others, add the features
            siz = numel(mtlcell{c});
            val = str2double(mtlcell{c}(2:siz));
            if ~isnan(val),
                mtl.(matname).(mfeat) = val;
            else
                mtl.(matname).(mfeat) = mtlcell{c}{2};
            end
    end
end

% Now take only the selected ones
if nargin == 2,

    % Make sure it's a cell with a list
    matnames = varargin{2};
    if ~iscell(matnames) && ischar(matnames),
        matnames = { matnames };
    end

    % Loop over materials
    for m = 1:numel(matnames),

        % Test if the material really exists
        if isfield(mtl,matnames{m}),
            mtlsel.(matnames{m}) = mtl.(matnames{m});
        else
            warning('Material ''%s'' not in %s.',matnames{m},fname);
        end
    end

    % Outputs the selected
    mtl = mtlsel;
end
