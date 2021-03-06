classdef GaussianApproximation
    methods(Static)
        %% GAUSSIANAPPROXIMATION TOOLKIT
        %
        % Written by Curtis Aquino (2019). Contains:
        %
        % # Initializiation() is required for all functions to run. 
        % # Polynomial() returns numerical solutions for the first N polynomials for a class of Gaussian polynomials evaluated at a set of points. If no points are entered, the symbolic expression for the Nth Gaussian polynomial is returned.
        % # NodesWeights() finds the nodes and weights for a variety of Gaussian polynomials numerically.
        % # Interpolate() interpolates (X,Y) data using an Nth order polynomial for a variety of Gaussian polynomials.
   
%% 1. INITIALIZATION      
function F          = Initialization(GaussianPolynomial)
    Types   = {
            'Gauss-Legendre';...
            'Gauss-Chebyshev';...
            'Gauss-Hermite';...
            'Gauss-Laguerre'
            };        
    F       = find(strcmp(GaussianPolynomial,Types));
    if isempty(F); fprintf('Invalid polynomial name'); return; end
end
%% 2. POLYNOMIAL
function F          = Polynomial(Degree,GaussianPolynomial,X)
    % For testing:
    %GaussianPolynomial = 'Gauss-Chebyshev'; PolynomialOrder = 4;
    
    % ==============
    % Initialization
    % ==============
    
    T                   = GaussianApproximation.Initialization(GaussianPolynomial);
    
    % =======================
    % Symbolic Representation
    % =======================
    
    % If no X is specified, this will recursively build the symbolic 
    % representation of the first N polynomials.
    
    if nargin < 3
        N               = Degree+1;
        X               = sym('X','real');
        P               = sym(zeros(N,1));
        P(1)            = 1;
        if T == 1
            Coef        = [[0,0,X.*(2.*(1:N)+1)./(2:(N+1))];[0,0,(1:N)./(2:(N+1))]];
            P(2)        = X;
        end
        if T == 2
            Coef        = [[0,0,repmat(2*X,1,N)]; [0,0,ones(1,N)]];
            P(2)        = X;
        end
        if T == 3
            Coef        = [[0,0,repmat(2*X,1,N)]; [0,0,2*(1:N)]];
            P(2)        = 2*X;
        end
        if T == 4
            Coef        = [[0,0,(2.*(1:N)+1-X)./(2:(N+1))];[0,0,(1:N)./(2:(N+1))]];
            P(2)        = 1-X;
        end
        for i = 3:N
            P(i) =  Coef(1,i)*P(i-1)-Coef(2,i)*P(i-2);
        end
        F = P;
    else
        
    % ==================
    % Numerical Solution
    % ==================
    
    % If X is specified, this will recursively evaluate the first N
    % polynomials.
        
        % Numerical solutions given X data
        n               = Degree+1;
        XLen            = length(X);
        if isrow(X); X = X'; end
        F(:,1) = ones(XLen,1);
        if T == 1
            Coef(:,:,1) = [zeros(XLen,2),(X.*(2.*(1:n)+1))./(2:(n+1))]; 
            Coef(:,:,2) = repmat([0,0,(1:n)./(2:(n+1))],XLen,1);
            F(:,2) = X;
        end
        if T == 2
            Coef(:,:,1) = [zeros(XLen,2),repmat(2*X,1,n)];
            Coef(:,:,2) = repmat([0,0,ones(1,n)],XLen,1);
            F(:,2) = X;
        end
        if T == 3
            Coef(:,:,1) = [zeros(XLen,2),repmat(2*X,1,n)];
            Coef(:,:,2) = repmat([0,0,2*(1:n)],XLen,1);
            F(:,2) = 2*X;
        end
        if T == 4
            Coef(:,:,1) = [zeros(XLen,2),(2.*(1:n)+1-X)./(2:(n+1))]; 
            Coef(:,:,2) = repmat([0,0,(1:n)./(2:(n+1))],XLen,1);
            F(:,2) = 1-X;
        end
        for i = 3:n
            F(:,i) = Coef(:,i,1).*F(:,i-1)-Coef(:,i,2).*F(:,i-2);
        end
        for i = 1:n
            ColName{i} = sprintf('Degree%i',i-1); %#ok<AGROW>
        end
        F  = array2table(F,'VariableNames',ColName);
    end
end
%% 3. NODESWEIGHTS
function F          = NodesWeights(Degree,GaussianPolynomial)
    
    % ==============
    % Initialization 
    % ==============
    
    n       = Degree;
    T       = GaussianApproximation.Initialization(GaussianPolynomial);
    Fn      = @(X) GaussianApproximation.Polynomial(n,GaussianPolynomial,X);
    
    % ================
    % Determine Ranges
    % ================
    
    % The range of each set of nodes are bounded, which can be proven.
    
    if T == 2
        Nd      = -cos((2*(1:n)-1)*pi/(2*n))';
        Wt      = repmat(pi/n,n,1);
    else
        if T == 1
            Range       = [-1,1];
        end
        if T == 3
            Range       = [-sqrt(4*n+1),sqrt(4*n+1)];
        end
        if T == 4
            Range       = [0,n+(n-1)*sqrt(n)];
        end
    
        % =========
        % Root Grid
        % =========
        
        % This will build a very fine grid over the range of the nodes and
        % save all points in which the value of the polynomial changes
        % signs.
        
        GridPrecision = 100000;
        IntBi   = linspace(Range(1),Range(2),GridPrecision);
        Roots   = Fn(IntBi);
        Roots   = Roots{:,end};
        SgnChg  = [diff(sign(Roots)) ~= 0];
        Grid    = [[Range(1),IntBi(SgnChg)]',[IntBi(SgnChg),Range(2)]'];
        
        % ============
        % Root Subgrid
        % ============
        
        % This will build a very fine subgrid over each range where a root
        % is known to be. This is used with the goal of finding the root to
        % a machine epsilon degree of accuracy.
        
        SubGridPrec     = 5000;
        SGrid           = [];
        for j = 1:size(Grid,1)
            IntBi   = linspace(Grid(j,1),Grid(j,2),SubGridPrec);
            Roots   = Fn(IntBi);
            Roots   = Roots{:,end};
            SgnChg  = [diff(sign(Roots)) ~= 0;false];
            Idx     = find(SgnChg == 1);
            if Idx == 1
                SGrid   = [SGrid;IntBi([find(SgnChg == 1),find(SgnChg == 1)+1])];
            elseif Idx == SubGridPrec
                SGrid   = [SGrid;IntBi([find(SgnChg == 1)-1,find(SgnChg == 1)])];
            else 
                SGrid   = [SGrid;IntBi([find(SgnChg == 1)-1,find(SgnChg == 1)+1])];
            end
        end
        
        % =========
        % Bisection
        % =========
        
        % Given the subgrids, this will vectorize a bisection over each
        % range to find each node.
        
        Bisection   = table(SGrid(:,1),SGrid(:,2),mean(SGrid,2),zeros(size(SGrid,1),1),'VariableNames',{'LoBi','HiBi','Guess','F'});
        itr = 1; thr1 = Inf; thr2 = Inf;
        while thr1 > 10^(-16) && thr2 > 10^(-16) && itr < 5000
            Roots       = Fn(Bisection.Guess);
            Bisection.F = Roots{:,n+1};
            Bisection(mod(1:size(Bisection,1),2)==1,:).F = Bisection(mod(1:size(Bisection,1),2)==1,:).F*-1;
            Bisection.LoBi(Bisection.F<0) = Bisection.Guess(Bisection.F<0);
            Bisection.HiBi(Bisection.F>0) = Bisection.Guess(Bisection.F>0);
            thr2        = norm(Bisection.Guess - mean([Bisection.LoBi,Bisection.HiBi],2));
            itr         = itr + 1;
            thr1        = norm(Bisection.F);
            Bisection.Guess = mean([Bisection.LoBi,Bisection.HiBi],2);
        end
        Nd       = Bisection.Guess;
        
        % ======
        % Unique
        % ======
        
        % Since nodes are determined by 
        
        for i = 16:-1:1
            Ndtest  = uniquetol(Nd,10^(-i));
            if length(Ndtest) == n
               Nd = sort(Ndtest);
               i = 1;
            end
        end
        
        % =======
        % Weights
        % =======
        
        % Weights have an explicit functional form, found online.
        
        temp = GaussianApproximation.Polynomial(n+1,GaussianPolynomial,Nd);
        if T == 1 
            Wt = (2*(1-Nd.^2))./((n+1)^2*temp{:,end}.^2);
        end
        if T ==3 
            Wt = (2^(n+1)*factorial(n)*sqrt(pi))./(temp{:,end}.^2);
        end
        if T == 4
            Wt = Nd./((n+1)^2*temp{:,end}.^2);
        end
    end
    
    % =======
    % Results
    % =======
   
    F = table(Nd,Wt,'VariableNames',{'Nodes','Weights'});
    
    % Uncomment for plots!
%     subplot(1,2,1)
%     plot(1:n,F.Nodes)
%     title('Nodes')
%     subplot(1,2,2)
%     plot(1:n,F.Weights)
%     title('Weights')
end    
%% 4. INTERPOLATE
function F          = Interpolate(Y,X,Degree,GaussianPolynomial,X0)
    if isrow(Y); Y = Y'; end
    if isrow(X); X = X'; end
    poly    = GaussianApproximation.Polynomial(Degree,GaussianPolynomial);
    c       = double(sum(Y.*reshape(subs(poly,X),[],Degree+1))./sum(reshape(subs(poly,X),[],Degree+1).^2));
    if nargin < 5
        F       = sum(c'.*poly);
    else
        F       = matlabFunction(sum(c'.*poly));
        F       = F(X0);
    end
end
    end
end