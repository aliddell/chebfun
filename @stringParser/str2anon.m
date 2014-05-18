function varargout = str2anon(str, problemType, fieldType)
% STRCONV2ANON Converts a string on 'natural syntax form' to an anonymous
% function Matlab and CHEBGUI can work with.

% TODO:  Documentation.

% Copyright 2014 by The University of Oxford and The Chebfun Developers. 
% See http://www.chebfun.org/chebfun/ for Chebfun information.

if ( nargin < 3 )
    fieldType = [];
end

% Put the original string through the lexer
[lexOut, varNames, pdeVarNames, eigVarNames, indVarNames] = ...
    stringParser.lexer(str, problemType);

% Make sure we have enough variables! If parsing the initial guess, and we
% have a scalar problem, we allow that the dependent variable doesn't
% appear.
if ( isempty(varNames) && ~strcmp(fieldType,'INITSCALAR') )
    if ( (numel(indVarNames) > 1) && ~isempty(indVarNames{2}) )
        str = sprintf('Variables ''%s'' and ''%s'' ', indVarNames{1:2});
    else
        str = sprintf('Variable ''%s'' ', indVarNames{1});
    end

    % Throw an informative error message, depending on whether we're
    % setting up a DE/BCs or an initial guess for a system.
    if ( ~strcmp(fieldType,'INIT') )
        error('Chebgui:chebgui:depvars', ...
            ['No dependent variables detected. ' str ...
             'treated as independent.']);
    else
        error('Chebgui:chebgui:depvars', ...
            ['No dependent variables detected in the initial field. Input ' ...
             'must be of the form "u = x, v = 2*x, ...']);
    end
end 

% Check whether we have something like u" = u_t+v_t which we don't allow
if ( length(pdeVarNames) > 1 )
    error('CHEBFUN:CHEBGUI:strConv2anon:pdeVariables', ...
        'Only one time derivative per line is allowed');
end

% Parse the output from the lexer, looking for syntax errors.
syntaxTree = stringParser.parser(lexOut);

if ( strcmp(problemType, 'bvp') )
    % Convert a potential = at the top of the tree to a -.
    syntaxTree = stringParser.splitTree(syntaxTree);
    % Obtain the prefix form.
    prefixOut = stringParser.tree2prefix(syntaxTree);
    
elseif ( strcmp(problemType, 'pde') )
    % Convert a potential = at the top of the tree to a -.
    [syntaxTree, pdeSign] = stringParser.splitTreePDE(syntaxTree);
    % Obtain the prefix form.
    prefixOut = stringParser.tree2prefix(syntaxTree);
    % pdeSign tells us whether we need to flip the signs. Add a unitary -
    % at the beginning of the expression
    if ( pdeSign == 1 )
        prefixOut = [{'-', 'UN-'} ; prefixOut];
    end
    
elseif ( strcmp(problemType, 'eig') )
    anFunLambda = '';
    % Convert a potential at the top of the tree = to a -.
    [syntaxTree, lambdaTree, lambdaSign] = stringParser.splitTreeEIG(syntaxTree);
    % Obtain the prefix form.
    prefixOut = stringParser.tree2prefix(syntaxTree);
    
    % If lambdaTree is not empty, convert that tree to prefix-form as well
    if ( ~isempty(lambdaTree) )
        prefixOutLambda = stringParser.tree2prefix(lambdaTree);
        
        % If the lambda part is on the LHS, we need to add a - in front of
        % the prefix expression.
        if ( lambdaSign == -1 )
            prefixOutLambda = [{'-', 'UN-'} ; prefixOutLambda];
        end
        
        % If we're in EIG mode, we want to replace lambda by 1
        if ( ~isempty(eigVarNames) )
            eigvarLoc = find(ismember(prefixOutLambda(:,2), 'LAMBDA') == 1);
            prefixOutLambda(eigvarLoc,1) = ...
                cellstr(repmat('1', length(eigvarLoc), 1));
            prefixOutLambda(eigvarLoc,2) = ...
                cellstr(repmat('NUM', length(eigvarLoc), 1));
        end

        % Change it to infix form and remove uneccessary parenthesis.
        infixOutLambda = stringParser.pref2inf(prefixOutLambda);
        anFunLambda = stringParser.parSimp(infixOutLambda);
    end
    
end

% Check whether we have equations divided by commas. This will only have
% happened if we have any commas left in the prefix expression
commaSeparated = any(strcmp(prefixOut(:,2), 'COMMA'));

[infixOut, notaVAR] = stringParser.pref2inf(prefixOut);
anFun = stringParser.parSimp(infixOut);

% Remove misinterpreted VARs (from Fred, Volt, etc)
for k = numel(varNames):-1:1
    if ( any(strcmp(varNames{k}, notaVAR)) )
        varNames(k) = [];
    end
end 
 
% Convert the cell array varNames into one string. Not required when we're
% working with the initial guess of scalar problems. If varNames is empty
% for other kind of problems, an error would already have been thrown.
if ( ~isempty(varNames) && ~strcmp(fieldType, 'INITSCALAR') )
    varString = varNames{1};
    for varCounter = 2:length(varNames)
        varString = [varString, ',', varNames{varCounter}];
    end

    if ( length(varNames) == 1 )
        anFunComplete = ['@(' varString ') ' anFun];
    else
        anFunComplete = ['@(' varString ') [' anFun ']'];
    end
end

% Also return the lambda part if we are in EIG mode
if ( strcmp(problemType, 'eig') && ~isempty(anFunLambda) )
    anFunLambdaComplete = ['@(' varString ') ' anFunLambda];
    anFunComplete = {anFunComplete ; anFunLambdaComplete};
    anFun = {anFun ; anFunLambda};
end

switch ( nargout )
    case 1
        varargout{1} = anFunComplete;
    case 2
        varargout{1} = anFunComplete;
        varargout{2} = indVarNames;
    case 3
        varargout{1} = anFun;
        varargout{2} = indVarNames;
        varargout{3} = varNames;
    case 4
        varargout{1} = anFun;
        varargout{2} = indVarNames;
        varargout{3} = varNames;
        varargout{4} = pdeVarNames;
    case 5
        varargout{1} = anFun;
        varargout{2} = indVarNames;
        varargout{3} = varNames;
        varargout{4} = pdeVarNames;
        varargout{5} = eigVarNames;
    case 6
        varargout{1} = anFun;
        varargout{2} = indVarNames;
        varargout{3} = varNames;
        varargout{4} = pdeVarNames;
        varargout{5} = eigVarNames;
        varargout{6} = commaSeparated;
end

end
