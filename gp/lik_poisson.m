function lik = lik_poisson(varargin)
%LIK_POISSON   Create a Poisson likelihood structure 
%
%  Description
%    LIK = LIK_POISSON creates Poisson likelihood structure
%
%    The likelihood is defined as follows:
%                  __ n
%      p(y|f, z) = || i=1 Poisson(y_i|z_i*exp(f_i))
%
%      where z is a vector of expected mean and f the latent value
%      vector whose components are transformed to relative risk
%      exp(f_i). 
%  
%    When using the Poisson likelihood you need to give the vector
%    z as an extra parameter to each function that requires y also. 
%    For example, you should call gpla_e as follows 
%    gpla_e(w, gp, x, y, 'z', z)
%
%  See also
%    GP_SET, LIK_*
%
  
% Copyright (c) 2006-2010 Jarno Vanhatalo
% Copyright (c) 2010 Aki Vehtari

% This software is distributed under the GNU General Public
% License (version 2 or later); please refer to the file
% License.txt, included with the software, for details.

  ip=inputParser;
  ip.FunctionName = 'LIK_POISSON';
  ip.addOptional('lik', [], @isstruct);
  ip.parse(varargin{:});
  lik=ip.Results.lik;

  if isempty(lik)
    init=true;
    lik.type = 'Poisson';
  else
    if ~isfield(lik,'type') && ~isequal(lik.type,'Poisson')
      error('First argument does not seem to be a valid likelihood function structure')
    end
    init=false;
  end

  if init
    % Set the function handles to the nested functions
    lik.fh.pak = @lik_poisson_pak;
    lik.fh.unpak = @lik_poisson_unpak;
    lik.fh.ll = @lik_poisson_ll;
    lik.fh.llg = @lik_poisson_llg;    
    lik.fh.llg2 = @lik_poisson_llg2;
    lik.fh.llg3 = @lik_poisson_llg3;
    lik.fh.tiltedMoments = @lik_poisson_tiltedMoments;
    lik.fh.predy = @lik_poisson_predy;
    lik.fh.recappend = @lik_poisson_recappend;
  end
  
  function [w,s] = lik_poisson_pak(lik)
  %LIK_POISSON_PAK  Combine likelihood parameters into one vector.
  %
  %  Description 
  %    W = LIK_POISSON_PAK(LIK) takes a likelihood structure LIK
  %    and returns an empty verctor W. If Poisson likelihood had
  %    parameters this would combine them into a single row vector
  %    W (see e.g. lik_negbin).
  %     
  %  See also
  %    LIK_NEGBIN_UNPAK, GP_PAK

    w = []; s = {};
  end


  function [lik, w] = lik_poisson_unpak(lik, w)
  %LIK_POISSON_UNPAK  Extract likelihood parameters from the vector.
  %
  %  Description
  %    W = LIK_POISSON_UNPAK(W, LIK) Doesn't do anything.
  %
  %    If Poisson likelihood had parameters this would extract them
  %    parameters from the vector W to the LIK structure.
  %     
  %
  %  See also
  %    LIK_POISSON_PAK, GP_UNPAK

    lik=lik;
    w=w;
    
  end


  function logLik = lik_poisson_ll(lik, y, f, z)
  %LIK_POISSON_LL    Log likelihood
  %
  %  Description
  %    E = LIK_POISSON_LL(LIK, Y, F, Z) takes a likelihood data
  %    structure LIK, incedence counts Y, expected counts Z, and
  %    latent values F. Returns the log likelihood, log p(y|f,z).
  %
  %  See also
  %    LIK_POISSON_LLG, LIK_POISSON_LLG3, LIK_POISSON_LLG2, GPLA_E

    
    if isempty(z)
      error(['lik_poisson -> lik_poisson_ll: missing z!'... 
             'Poisson likelihood needs the expected number of '...
             'occurrences as an extra input z. See, for       '...
             'example, lik_poisson and gpla_e.            ']);
    end
    
    lambda = z.*exp(f);
    gamlny = gammaln(y+1);
    logLik =  sum(-lambda + y.*log(lambda) - gamlny);
  end


  function deriv = lik_poisson_llg(lik, y, f, param, z)
  %LIK_POISSON_LLG    Gradient of the log likelihood
  %
  %  Description 
  %    G = LIK_POISSON_LLG(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, incedence counts Y, expected counts Z
  %    and latent values F. Returns the gradient of the log
  %    likelihood with respect to PARAM. At the moment PARAM can be
  %    'param' or 'latent'.
  %
  %  See also
  %    LIK_POISSON_LL, LIK_POISSON_LLG2, LIK_POISSON_LLG3, GPLA_E
    
    if isempty(z)
      error(['lik_poisson -> lik_poisson_llg: missing z!'... 
             'Poisson likelihood needs the expected number of '...
             'occurrences as an extra input z. See, for       '...
             'example, lik_poisson and gpla_e.            ']);
    end
    
    switch param
      case 'latent'
        deriv = y - z.*exp(f);
    end
  end


  function g2 = lik_poisson_llg2(lik, y, f, param, z)
  %LIK_POISSON_LLG2  Second gradients of the log likelihood
  %
  %  Description        
  %    G2 = LIK_POISSON_LLG2(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, incedence counts Y, expected counts Z,
  %    and latent values F. Returns the hessian of the log
  %    likelihood with respect to PARAM. At the moment PARAM can be
  %    only 'latent'. G2 is a vector with diagonal elements of the
  %    hessian matrix (off diagonals are zero).
  %
  %  See also
  %    LIK_POISSON_LL, LIK_POISSON_LLG, LIK_POISSON_LLG3, GPLA_E

    if isempty(z)
      error(['lik_poisson -> lik_poisson_llg2: missing z!'... 
             'Poisson likelihood needs the expected number of  '...
             'occurrences as an extra input z. See, for        '...
             'example, lik_poisson and gpla_e.             ']);
    end
    
    switch param
      case 'latent'
        g2 = -z.*exp(f);
    end
  end    
  
  function third_grad = lik_poisson_llg3(lik, y, f, param, z)
  %LIK_POISSON_LLG3  Third gradients of the log likelihood
  %
  %  Description
  %    G3 = LIK_POISSON_LLG3(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, incedence counts Y, expected counts Z
  %    and latent values F and returns the third gradients of the
  %    log likelihood with respect to PARAM. At the moment PARAM
  %    can be only 'latent'. G3 is a vector with third gradients.
  %
  %  See also
  %    LIK_POISSON_LL, LIK_POISSON_LLG, LIK_POISSON_LLG2, GPLA_E, GPLA_G
    
    if isempty(z)
      error(['lik_poisson -> lik_poisson_llg3: missing z!'... 
             'Poisson likelihood needs the expected number of  '...
             'occurrences as an extra input z. See, for        '...
             'example, lik_poisson and gpla_e.             ']);
    end
    
    switch param
      case 'latent'
        third_grad = - z.*exp(f);
    end
  end

  function [m_0, m_1, sigm2hati1] = lik_poisson_tiltedMoments(lik, y, i1, sigm2_i, myy_i, z)
  %LIK_POISSON_TILTEDMOMENTS  Returns the marginal moments for EP algorithm
  %
  %  Description
  %    [M_0, M_1, M2] = LIK_POISSON_TILTEDMOMENTS(LIK, Y, I, S2,
  %    MYY, Z) takes a likelihood structure LIK, incedence counts
  %    Y, expected counts Z, index I and cavity variance S2 and
  %    mean MYY. Returns the zeroth moment M_0, mean M_1 and
  %    variance M_2 of the posterior marginal (see Rasmussen and
  %    Williams (2006): Gaussian processes for Machine Learning,
  %    page 55).
  %
  %  See also
  %    GPEP_E

    
    if isempty(z)
      error(['lik_poisson -> lik_poisson_tiltedMoments: missing z!'... 
             'Poisson likelihood needs the expected number of             '...
             'occurrences as an extra input z. See, for                   '...
             'example, lik_poisson and gpla_e.                        ']);
    end
    
    yy = y(i1);
    avgE = z(i1);
    
    % get a function handle of an unnormalized tilted distribution 
    % (likelihood * cavity = Negative-binomial * Gaussian)
    % and useful integration limits
    [tf,minf,maxf]=init_poisson_norm(yy,myy_i,sigm2_i,avgE);
    
    % Integrate with quadrature
    RTOL = 1.e-6;
    ATOL = 1.e-10;
    [m_0, m_1, m_2] = quad_moments(tf, minf, maxf, RTOL, ATOL);
    sigm2hati1 = m_2 - m_1.^2;
    
    % If the second central moment is less than cavity variance
    % integrate more precisely. Theoretically for log-concave
    % likelihood should be sigm2hati1 < sigm2_i.
    if sigm2hati1 >= sigm2_i
      ATOL = ATOL.^2;
      RTOL = RTOL.^2;
      [m_0, m_1, m_2] = quad_moments(tf, minf, maxf, RTOL, ATOL);
      sigm2hati1 = m_2 - m_1.^2;
      if sigm2hati1 >= sigm2_i
        error('lik_poisson_tilted_moments: sigm2hati1 >= sigm2_i');
      end
    end
  end

  
  function [Ey, Vary, Py] = lik_poisson_predy(lik, Ef, Varf, yt, zt)
  %LIK_POISSON_PREDY    Returns the predictive mean, variance and density of y
  %
  %  Description         
  %    [EY, VARY] = LIK_POISSON_PREDY(LIK, EF, VARF) takes a
  %    likelihood structure LIK, posterior mean EF and posterior
  %    Variance VARF of the latent variable and returns the
  %    posterior predictive mean EY and variance VARY of the
  %    observations related to the latent variables
  %        
  %    [Ey, Vary, PY] = LIK_POISSON_PREDY(LIK, EF, VARF YT, ZT)
  %    Returns also the predictive density of YT, that is 
  %        p(yt | y,zt) = \int p(yt | f, zt) p(f|y) df.
  %    This requires also the incedence counts YT, expected counts ZT.
  %
  %  See also 
  %    GPLA_PRED, GPEP_PRED, GPMC_PRED

    if isempty(zt)
      error(['lik_poisson -> lik_poisson_predy: missing zt!'... 
             'Poisson likelihood needs the expected number of     '...
             'occurrences as an extra input zt. See, for           '...
             'example, lik_poisson and gpla_e.                ']);
    end
    
    avgE = zt;
    Py = zeros(size(Ef));
    Ey = zeros(size(Ef));
    EVary = zeros(size(Ef));
    VarEy = zeros(size(Ef)); 
    
    % Evaluate Ey and Vary
    for i1=1:length(Ef)
      %%% With quadrature
      myy_i = Ef(i1);
      sigm_i = sqrt(Varf(i1));
      minf=myy_i-6*sigm_i;
      maxf=myy_i+6*sigm_i;

      F = @(f) exp(log(avgE(i1))+f+norm_lpdf(f,myy_i,sigm_i));
      Ey(i1) = quadgk(F,minf,maxf);
      
      EVary(i1) = Ey(i1);
      
      F3 = @(f) exp(2*log(avgE(i1))+2*f+norm_lpdf(f,myy_i,sigm_i));
      VarEy(i1) = quadgk(F3,minf,maxf) - Ey(i1).^2;
    end
    Vary = EVary + VarEy;

    % Evaluate the posterior predictive densities of the given observations
    if nargout > 2
      for i1=1:length(Ef)
        % get a function handle of the likelihood times posterior
        % (likelihood * posterior = Poisson * Gaussian)
        % and useful integration limits
        [pdf,minf,maxf]=init_poisson_norm(...
          yt(i1),Ef(i1),Varf(i1),avgE(i1));
        % integrate over the f to get posterior predictive distribution
        Py(i1) = quadgk(pdf, minf, maxf);
      end
    end
  end
  
  function [df,minf,maxf] = init_poisson_norm(yy,myy_i,sigm2_i,avgE)
  %INIT_POISSON_NORM
  %
  %  Description
  %    Return function handle to a function evaluating Poisson *
  %    Gaussian which is used for evaluating (likelihood * cavity)
  %    or (likelihood * posterior) Return also useful limits for
  %    integration. This is private function for lik_poisson.
  %  
  %  See also
  %    LIK_POISSON_TILTEDMOMENTS, LIK_POISSON_PREDY
    
  % avoid repetitive evaluation of constant part
    ldconst = -gammaln(yy+1) - log(sigm2_i)/2 - log(2*pi)/2;
    
    % Create function handle for the function to be integrated
    df = @poisson_norm;
    % use log to avoid underflow, and derivates for faster search
    ld = @log_poisson_norm;
    ldg = @log_poisson_norm_g;
    ldg2 = @log_poisson_norm_g2;

    % Set the limits for integration
    % Poisson likelihood is log-concave so the poisson_norm
    % function is unimodal, which makes things easier
    if yy==0
      % with yy==0, the mode of the likelihood is not defined
      % use the mode of the Gaussian (cavity or posterior) as a first guess
      modef = myy_i;
    else
      % use precision weighted mean of the Gaussian approximation
      % of the Poisson likelihood and Gaussian
      mu=log(yy/avgE);
      s2=1./(yy+1./sigm2_i);
      modef = (myy_i/sigm2_i + mu/s2)/(1/sigm2_i + 1/s2);
    end
    % find the mode of the integrand using Newton iterations
    % few iterations is enough, since the first guess in the right direction
    niter=3;       % number of Newton iterations
    mindelta=1e-6; % tolerance in stopping Newton iterations
    for ni=1:niter
      g=ldg(modef);
      h=ldg2(modef);
      delta=-g/h;
      modef=modef+delta;
      if abs(delta)<mindelta
        break
      end
    end
    % integrand limits based on Gaussian approximation at mode
    modes=sqrt(-1/h);
    minf=modef-8*modes;
    maxf=modef+8*modes;
    modeld=ld(modef);
    iter=0;
    % check that density at end points is low enough
    lddiff=20; % min difference in log-density between mode and end-points
    minld=ld(minf);
    while minld>(modeld-lddiff)
      minf=minf-(modes-minf);
      minld=ld(minf);
      iter=iter+1;
      if iter>100
        error(['lik_poisson -> init_poisson_norm: ' ...
               'integration interval minimun not found ' ...
               'even after looking hard!'])
      end
    end
    maxld=ld(maxf);
    while maxld>(modeld-lddiff)
      maxf=maxf+(maxf-modes);
      maxld=ld(maxf);
      iter=iter+1;
      if iter>100
        error(['lik_poisson -> init_poisson_norm: ' ...
               'integration interval maximum not found ' ...
               'even after looking hard!'])
      end
      
    end
    
    function integrand = poisson_norm(f)
    % Poisson * Gaussian
      mu = avgE.*exp(f);
      integrand = exp(ldconst ...
                      -mu+yy.*log(mu) ...
                      -0.5*(f-myy_i).^2./sigm2_i);
    end
    
    function log_int = log_poisson_norm(f)
    % log(Poisson * Gaussian)
    % log_poisson_norm is used to avoid underflow when searching
    % integration interval
      mu = avgE.*exp(f);
      log_int = ldconst ...
                -mu+yy.*log(mu) ...
                -0.5*(f-myy_i).^2./sigm2_i;
    end
    
    function g = log_poisson_norm_g(f)
    % d/df log(Poisson * Gaussian)
    % derivative of log_poisson_norm
      mu = avgE.*exp(f);
      g = -mu+yy...
          + (myy_i - f)./sigm2_i;
    end
    
    function g2 = log_poisson_norm_g2(f)
    % d^2/df^2 log(Poisson * Gaussian)
    % second derivate of log_poisson_norm
      mu = avgE.*exp(f);
      g2 = -mu...
           -1/sigm2_i;
    end
    
  end
  
  function reclik = lik_poisson_recappend(reclik, ri, lik)
  %RECAPPEND  Append the parameters to the record
  %
  %  Description 
  %    RECLIK = LIK_POISSON_RECAPPEND(RECLIK, RI, LIK) takes a
  %    likelihood record structure RECLIK, record index RI and
  %    likelihood structure LIK with the current MCMC samples of
  %    the parameters. Returns RECLIK which contains all the old
  %    samples and the current samples from LIK.
  % 
  %  See also
  %    GP_MC

    if nargin == 2
      reclik.type = 'Poisson';

      % Set the function handles
      reclik.fh.pak = @lik_poisson_pak;
      reclik.fh.unpak = @lik_poisson_unpak;
      reclik.fh.ll = @lik_poisson_ll;
      reclik.fh.llg = @lik_poisson_llg;    
      reclik.fh.llg2 = @lik_poisson_llg2;
      reclik.fh.llg3 = @lik_poisson_llg3;
      reclik.fh.tiltedMoments = @lik_poisson_tiltedMoments;
      reclik.fh.predy = @lik_poisson_predy;
      reclik.fh.recappend = @lik_poisson_recappend;
      return
    end
    
  end
end

