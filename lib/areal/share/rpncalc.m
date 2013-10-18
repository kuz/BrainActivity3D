% #!/usr/bin/octave -q
function rpncalc(varargin)
% Do some simple calculations using RPN notation.
% Accepted inputs are file names for DPV/DPF files, the
% operators +, -, *, /, and ^, l for logarithm of base 10,
% r to swap stack 1st and 2nd stack levels and d to
% duplicate the 1st level.
% All inputs must be strings (so, delimited with quotes '')
% The last input is the name of the file to be created,
% which will contain the current content of the 1st stack level.
% The vertex coordinates (for DPV) or the face indices (for DPF)
% will be the same as for the last DPV/DPF file loaded.
%
% _____________________________________
% Anderson M. Winkler
% Yale University / Institute of Living
% Jun/2011
% http://brainder.org

% Do the OCTAVE stuff, with TRY to ensure MATLAB compatibility
try
    % Get the inputs
    varargin = argv();
    
    % Disable memory dump on SIGTERM
    sigterm_dumps_octave_core(0);
    
    % Print usage if no inputs are given
    if isempty(varargin) || strcmp(varargin{1},'-q'),
        
        fprintf('Do some simple calculations using RPN notation.\n');
        fprintf('Accepted inputs are file names for curvatures, the \n');
        fprintf('operators +, -, *, /, and ^, l for logarithm of base 10,\n');
        fprintf('r to swap stack 1st and 2nd stack levels and d to\n');
        fprintf('duplicate the 1st level.\n');
        fprintf('All inputs must be strings (so, delimited with quotes '''')\n');
        fprintf('The last input is the name of the file to be created,\n');
        fprintf('which will contain the current content of the 1st stack level.\n');
        fprintf('The vertex coordinates (for DPV) or the face indices (for DPF)\n');
        fprintf('will be the same as for the last DPV/DPF file loaded.\n');
        fprintf('\n');
        fprintf('_____________________________________\n');
        fprintf('Anderson M. Winkler\n');
        fprintf('Yale University / Institute of Living\n');
        fprintf('Jun/2011\n');
        fprintf('http://brainder.org\n');
        return;
    end
end

% More OCTAVE stuff
nargin = numel(varargin);

% Define the operators
opadd = {'+';'-'};
opmul = {'*';'/';'^'};
oplogic = {'<','>','<=','>=','==','~='};

stack = cell(0,0);
for a = 1:(nargin-1),
    
    if exist(varargin{a},'file') == 2,            % LOAD DPF/DPV
        
        % If the current argument is a file, load it
        fprintf('Loading file: %s ',varargin{a})
        [~,~,fext] = fileparts(varargin{a});
        if any(strcmpi(fext,{'.dpv','.dpf','.dpx','.asc'})),
            fprintf('(as DPX file)\n');
            isdpx = true;
            [dat,crd,idx] = dpxread(varargin{a});
        else
            fprintf('(as CSV file)\n');
            isdpx = false;
            dat = csvread(varargin{a});
        end
        
        % And put it at the 1st level on the stack
        for s = numel(stack):-1:1,
            stack{s+1} = stack{s};
        end
        stack{1} = dat;
        
    elseif any(strcmp(opadd,varargin{a})),        % ADD/SUBTRACT
        
        % If the current argument is additive, execute it
        fprintf('Adding/Subtracting\n')
        stack{1} = eval(sprintf('stack{2} %s stack{1}',varargin{a}));
        stack(2) = [];
        
    elseif any(strcmp(opmul,varargin{a})),        % MULTIPLY/DIVIDE/POTENTIATE
        
        % If the current argument is multiplicative, execute it
        fprintf('Multiplicating/Dividing/Potentiating\n')
        stack{1} = eval(sprintf('stack{2} .%s stack{1}',varargin{a}));
        stack(2) = [];
        
    elseif any(strcmp(oplogic,varargin{a})),       % LOGICAL
        
        % If the current argument is multiplicative, execute it
        fprintf('Performing a logical operation\n')
        stack{1} = eval(sprintf('stack{2} %s stack{1}',varargin{a}));
        stack(2) = [];
        
    elseif strcmpi('l',varargin{a});              % LOGARITHM
        
        % Compute the log of the 1st element in the stack
        fprintf('Taking the logarithm\n')
        stack{1} = log10(stack{1});
        
    elseif strcmpi('r',varargin{a});              % SWAP
        
        % Swap the 2 top elements of the stack
        fprintf('Swapping stack elements\n')
        tmpvar = stack{1};
        stack{1} = stack{2};
        stack{2} = tmpvar;
        
    elseif strcmpi('d',varargin{a});              % DUPLICATE
        
        % Duplicate the 1st element of the stack
        fprintf('Duplicating stack elements\n')
        for s = numel(stack):-1:1,
            stack{s+1} = stack{s};
        end
        stack{1} = stack{2};
        
    elseif isreal(str2num(varargin{a})),          % NUMBER
        
        % If the current argument is a number, take it
        fprintf('Entering scalar: %g\n',str2num(varargin{a}))
        for s = numel(stack):-1:1,
            stack{s+1} = stack{s};
        end
        stack{1} = str2num(varargin{a});
        
    end
end

% Save result
if isdpx,
    dpxwrite(varargin{nargin},stack{1},crd,idx);
else
    csvwrite(varargin{nargin},stack{1});
end
