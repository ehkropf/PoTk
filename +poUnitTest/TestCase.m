classdef(Abstract) TestCase < matlab.unittest.TestCase
%poUnitTest.TestCase is the abstract subclass of the matlab TestCase for
%the PoTk.

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

properties
    perTestTolerance
    defaultTolerance = 1e-12
    
    diagnosticMessage
end

properties(Abstract)
    domainTestObject        % Instance of domainForTest
end

properties(Dependent)
    domainObject            % Instance of potentialDomain
    primeFunctionReferenceForDomain
end
methods % getters
    function do = get.domainObject(test)
        do = test.domainTestObject.domainObject;
    end
    
    function pf = get.primeFunctionReferenceForDomain(test)
        label = test.domainTestObject.label;
        switch label
            case {'entire', 'simple'}
                pf = @(z,a) z - a;
                
            case 'annulus'
                q = test.domainObject.qv;
                [P, C] = poUnitTest.PFunction(q);
                pf = @(z,a) a*C*P(z/a);
                
            otherwise
                L = 8;
                dv = test.domainObject.dv;
                qv = test.domainObject.qv;
                pf = poUnitTest.SKProd(dv, qv, L);
        end
    end
end

methods(TestMethodSetup)
    function resetPerTestTolerance(test)
        test.perTestTolerance = [];
    end
end

methods
    function checkAtTestPoints(test, ref, fun)
        tol = test.determineTolerance(ref);
        
        zp = test.domainTestObject.testPoints;
        err = ref(zp) - fun(zp);
        
        msg = test.diagnosticMessage;
        if isempty(msg)
            args = {tol};
        else
            args = {tol, msg};
        end
        test.verifyLessThan(max(abs(err(:))), args{:})
    end
    
    function tol = determineTolerance(test, ref)
        tol = test.perTestTolerance;
        if isempty(tol) && ...
                nargin > 1 && isa(ref, 'poUnitTest.ReferenceFunction')
            tol = ref.tolerance;
        end
        if isempty(tol)
            tol = test.defaultTolerance;
        end
    end
end

end
