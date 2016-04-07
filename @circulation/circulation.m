classdef circulation < double & potentialKind
%circulation is a vector of boundary circulation values.

% Everett Kropf, 2016
% 
% This file is part of the Potential Toolkit (PoTk).
% 
% PoTk is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% PoTk is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with PoTk.  If not, see <http://www.gnu.org/licenses/>.

properties(Access=protected)
    firstKindIntegrals
end

methods
    function C = circulation(varargin)
        if ~nargin
            data = [];
        elseif nargin == 1
            data = varargin{1};
        else
            data = cell2mat(varargin);
        end
        
        % FIXME: Check that input data is real only.
        C = C@double(data);
    end
    
    function val = evalPotential(C, z)
        val = complex(zeros(size(z)));
        circ = double(C);
        vj = C.firstKindIntegrals;
        
        for j = find(circ(:) ~= 0)'
            val = val + circ(j)*vj{j}(z);
        end
    end
    
    function C = setupPotential(C, W)
        D = skpDomain(W.theDomain);
        circ = double(C);
        if numel(circ) ~= D.m
            error(PoTk.ErrorTypeString.RuntimeError, ...
                ['The number of circulation values and inner circles ' ...
                'must match.'])
        end
        
        vj = cell(1, numel(circ));
        for j = find(circ(:) ~= 0)'
            vj{j} = vjFirstKind(j, D);
        end
        C.firstKindIntegrals = vj;
    end
end

end
