function dpxstats(varargin)
% Display some statistics for a DPF or DPV file.
% If more than one file is specified, and if all contain
% the same number of datapoints, it prints also
% the correlation matrix.
% 
% Usage:
% dpxstats('file1.dpf','file2.dpf','file3.dpf',...)
% 
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jul/2011
% http://brainder.org

% Do some OCTAVE stuff, but use TRY to ensure MATLAB compatibility
try
    % Get the inputs
    varargin = argv();
    nargin = numel(varargin);

    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);

    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),
        fprintf('Display some statistics for a DPF or DPV file.\n');
        fprintf('If more than one file is specified, and if all contain\n');
        fprintf('the same number of datapoints, it prints also\n');
        fprintf('the correlation matrix.\n');
        fprintf('\n');
        fprintf('Usage:\n');
        fprintf('dpxstats <file1.dpf> [file2.dpf] [file3.dpf] ...\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Jul/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
end

% Loop over images
dpx   = cell(nargin,1);
nD    = zeros(nargin,1);
nvoid = zeros(nargin,1);
for a = 1:nargin,

    % Read the file
    dpx{a} = dpxread(varargin{a});

    % Number of datapoints (faces or vertices)
    nD(a)    = numel(dpx{a});
    didx     = ~isnan(dpx{a}) & ~isinf(dpx{a});
    nvoid(a) = sum(~didx);

    % Print statistics
    fprintf('Filename: %s\n',varargin{a});
    fprintf('# of points: %d\n',nD(a));
    fprintf('# of points marked as NaN or Inf: %d (%d%%)\n',nvoid(a),100*nvoid(a)/nD(a));
    fprintf('Mean:     %f\n',mean(dpx{a}(didx)));
    fprintf('Std:      %f\n',std(dpx{a}(didx)));
    fprintf('Min:      %f\n',min(dpx{a}(didx)));
    fprintf('Max:      %f\n',max(dpx{a}(didx)));
    fprintf('Median:   %f\n',median(dpx{a}(didx)));
    fprintf('Mode:     %f\n',mode(dpx{a}(didx)));
    fprintf('Sum:      %f\n\n',sum(dpx{a}(didx)));

end

% If the number of datapoints is the same for all
if nargin > 1 && numel(unique(nD)) == 1 && numel(unique(nvoid)) == 1;

    % Initialize & assemble a matrix
    dpxall = zeros(nD(1)-nvoid(1),nargin);
    for a = 1:nargin,
        didx = ~isnan(dpx{a}) & ~isinf(dpx{a});
        dpxall(:,a) = dpx{a}(didx);
    end

    % Compute & display the correlation matrix
    C = corrcoef(dpxall);
    disp('Correlation matrix:')
    disp(C);
else
    
    % If unavailable...
    fprintf('The number of datapoints is not the same for all files.\n');
    fprintf('Correlation matrix won''t be shown.\n');
end
