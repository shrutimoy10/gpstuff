function lik = lik_softmax(varargin)
%LIK_SOFTMAX    Create a softmax likelihood structure 
%
%  Description
%    LIK = LIK_SOFTMAX creates Softmax likelihood for multi-class
%    classification problem. The observed class label with C
%    classes is given as 1xC vector where C-1 entries are 0 and the
%    observed class label is 1.
%
%  See also
%    GP_SET, LIK_*

% Copyright (c) 2010 Jaakko Riihim�ki, Pasi Jyl�nki
% Copyright (c) 2010 Aki Vehtari

% This software is distributed under the GNU General Public
% License (version 2 or later); please refer to the file
% License.txt, included with the software, for details.

  ip=inputParser;
  ip.FunctionName = 'LIK_SOFTMAX';
  ip.addOptional('lik', [], @isstruct);
  ip.parse(varargin{:});
  lik=ip.Results.lik;

  if isempty(lik)
    init=true;
    lik.type = 'Softmax';
  else
    if ~isfield(lik,'type') && ~isequal(lik.type,'Softmax')
      error('First argument does not seem to be a valid likelihood function structure')
    end
    init=false;
  end

  if init
    % Set the function handles to the nested functions
    lik.fh.pak = @lik_softmax_pak;
    lik.fh.unpak = @lik_softmax_unpak;
    lik.fh.ll = @lik_softmax_ll;
    lik.fh.llg = @lik_softmax_llg;    
    lik.fh.llg2 = @lik_softmax_llg2;
    lik.fh.llg3 = @lik_softmax_llg3;
    lik.fh.tiltedMoments = @lik_softmax_tiltedMoments;
    lik.fh.predy = @lik_softmax_predy;
    lik.fh.recappend = @lik_softmax_recappend;
  end
  

  function [w,s] = lik_softmax_pak(lik)
  %LIK_LOGIT_PAK  Combine likelihood parameters into one vector.
  %
  %  Description 
  %    W = LIK_LOGIT_PAK(LIK) takes a likelihood structure LIK and
  %    returns an empty verctor W. If Logit likelihood had
  %    parameters this would combine them into a single row vector
  %    W (see e.g. lik_negbin).
  %     
  %
  %  See also
  %    LIK_NEGBIN_UNPAK, GP_PAK
    
    w = []; s = {};
  end


  function [lik, w] = lik_softmax_unpak(lik, w)
  %LIK_LOGIT_UNPAK  Extract likelihood parameters from the vector.
  %
  %  Description
  %    W = LIK_LOGIT_UNPAK(W, LIK) Doesn't do anything.
  % 
  %    If Logit likelihood had parameters this would extracts them
  %    parameters from the vector W to the LIK structure.
  %     
  %
  %  See also
  %    LIK_LOGIT_PAK, GP_UNPAK

    lik=lik;
    w=w;
  end


  function ll = lik_softmax_ll(lik, y, f2, z)
  %LIK_LOGIT_LL  Log likelihood
  %
  %  Description
  %    LL = LIK_LOGIT_LL(LIK, Y, F) takes a likelihood structure
  %    LIK, class labels Y (NxC matrix), and latent values F (NxC
  %    matrix). Returns the log likelihood, log p(y|f,z).
  %
  %  See also
  %    LIK_LOGIT_LLG, LIK_LOGIT_LLG3, LIK_LOGIT_LLG2, GPLA_E

    if ~isempty(find(y~=1 & y~=0))
      error('lik_softmax: The class labels have to be {0,1}')
    end
    
    % softmax:
    ll = y(:)'*f2(:) - sum(log(sum(exp(f2),2)));
    
  end


  function llg = lik_softmax_llg(lik, y, f2, param, z)
  %LIK_LOGIT_LLG    Gradient of the log likelihood
  %
  %  Description
  %    LLG = LIK_LOGIT_LLG(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, class labels Y, and latent values F. Returns
  %    the gradient of the log likelihood with respect to PARAM. At
  %    the moment PARAM can be 'param' or 'latent'.
  %
  %  See also
  %    LIK_LOGIT_LL, LIK_LOGIT_LLG2, LIK_LOGIT_LLG3, GPLA_E
    
    if ~isempty(find(y~=1 & y~=0))
      error('lik_softmax: The class labels have to be {0,1}')
    end

    expf2 = exp(f2);
    pi2 = expf2./(sum(expf2, 2)*ones(1,size(y,2)));
    pi_vec=pi2(:);
    llg = y(:)-pi_vec;
  end


  function llg2 = lik_softmax_llg2(lik, y, f2, param, z)
  %LIK_LOGIT_LLG2  Second gradients of the log likelihood
  %
  %  Description        
  %    LLG2 = LIK_LOGIT_LLG2(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, class labels Y, and latent values F. Returns
  %    the hessian of the log likelihood with respect to PARAM. At
  %    the moment PARAM can be only 'latent'. LLG2 is a vector with
  %    diagonal elements of the hessian matrix (off diagonals are
  %    zero).
  %
  %  See also
  %    LIK_LOGIT_LL, LIK_LOGIT_LLG, LIK_LOGIT_LLG3, GPLA_E

  % softmax:    
    expf2 = exp(f2);
    pi2 = expf2./(sum(expf2, 2)*ones(1,size(y,2)));
    pi_vec=pi2(:);
    [n,nout]=size(y);
    pi_mat=zeros(nout*n, n);
    for i1=1:nout
      pi_mat((1+(i1-1)*n):(nout*n+1):end)=pi2(:,i1);
    end
    D=diag(pi_vec);
    llg2=-D+pi_mat*pi_mat';
    
  end    
  
  function llg3 = lik_softmax_llg3(lik, y, f, param, z)
  %LIK_LOGIT_LLG3  Third gradients of the log likelihood
  %
  %  Description
  %    LLG3 = LIK_LOGIT_LLG3(LIK, Y, F, PARAM) takes a likelihood
  %    structure LIK, class labels Y, and latent values F and
  %    returns the third gradients of the log likelihood with
  %    respect to PARAM. At the moment PARAM can be only 'latent'. 
  %    LLG3 is a vector with third gradients.
  %
  %  See also
  %    LIK_LOGIT_LL, LIK_LOGIT_LLG, LIK_LOGIT_LLG2, GPLA_E, GPLA_G
    
    if ~isempty(find(y~=1 & y~=0))
      error('lik_softmax: The class labels have to be {0,1}')
    end
    
  end

  function [m_0, m_1, sigm2hati1] = lik_softmax_tiltedMoments(lik, y, i1, sigm2_i, myy_i, z)
  end
  
  function [Ey, Vary, py] = lik_softmax_predy(lik, Ef, Varf, y, z)
  end

  function reclik = lik_softmax_recappend(reclik, ri, lik)
  %RECAPPEND  Append the parameters to the record
  %
  %  Description 
  %    RECLIK = GPCF_LOGIT_RECAPPEND(RECLIK, RI, LIK) takes a
  %    likelihood record structure RECLIK, record index RI and
  %    likelihood structure LIK with the current MCMC samples of
  %    the parameters. Returns RECLIK which contains all the old
  %    samples and the current samples from LIK.
  % 
  %  See also
  %    GP_MC

    if nargin == 2
      reclik.type = 'softmax';

      % Set the function handles
      reclik.fh.pak = @lik_softmax_pak;
      reclik.fh.unpak = @lik_softmax_unpak;
      reclik.fh.ll = @lik_softmax_ll;
      reclik.fh.llg = @lik_softmax_llg;    
      reclik.fh.llg2 = @lik_softmax_llg2;
      reclik.fh.llg3 = @lik_softmax_llg3;
      reclik.fh.tiltedMoments = @lik_softmax_tiltedMoments;
      reclik.fh.predy = @lik_softmax_predy;
      reclik.fh.recappend = @lik_softmax_recappend;
      return
    end
    
  end
end