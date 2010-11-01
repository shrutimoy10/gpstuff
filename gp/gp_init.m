function gp = gp_init(do, varargin)
%GP_INIT	Create a Gaussian Process data structure.
%
%    Description
%     GP = GP_INIT('init', TYPE, 'LIKELIH', GPCF, NOISE, OPTIONS)
%     Creates a Gaussian Process model. TYPE defines the type of
%     GP. LIKELIH is a string/structure defining the likelihood. GPCF
%     and NOISE arrays consist of covariance function structures (see,
%     for example, gpcf_sexp, gpcf_noiset). At minimum one covariance
%     function has to be given. OPTIONS is optional parameter-value
%     pair used as described below with GP_INIT('set'...
%
%     GP = GP_INIT('set', GP, OPTIONS) Sets the fields of GP as
%     described by the parameter-value pairs ('FIELD', VALUE) in the
%     OPTIONS.
%
%     The minimum number of fields and their possible values are
%     the following:
%      type         = The type of Gaussian process
%                      'FULL'   full GP
%                      'FIC'    fully independent conditional sparse
%                               approximation
%                      'PIC'    partially independent condional
%                               sparse approximation
%                      'CS+FIC' compact support + FIC model sparse
%                               approximation
%                      'DTC'    deterministic training conditional
%                               sparse approximation
%                      'DTC'    subset of regressors sparse
%                               approximation
%                      'VAR'    variational sparse approximation
%      likelih      = The likelihood. If Gaussian noise is used this is
%                     string 'gaussian', otherwise this is structure created
%                     by one of the likelihood functions likelih_*.
%      cf           = cell array of covariance function structures
%                     created by gpcf_* functions
%      noise        = cell array of noise covariance function structures
%                     such as gpcf_noise or gpcf_noiset
%      infer_params = String defining which hyperparameters are inferred.
%                      'covariance'     = infer hyperparameters of
%                                         covariance function
%                      'likelihood'     = infer parameters of likelihood
%                      'inducing'       = infer inducing inputs (in sparse
%                                         approximations): W = gp.X_u(:)
%                       By combining the strings one can infer more than
%                       one group of parameters. For example:
%                      'covariance+inducing' = infer covariance function
%                                              parameters and inducing
%                                              inputs
%                      'covariance+likelih' = infer covariance function
%                                              and likelihood parameters
%                       The default is 'covariance+inducing+likelihood'
%      jitterSigma2 = positive jitter to be added in the diagonal of
%                      covariance matrix (default 0).
%      p            = field for prior structure of inducing inputs
%                       in sparse GPs
%
%     The additional fields needed with derivative observations
%      derivobs     = A flag variable so that derivative observations are
%                     in use. Provide with some value so that the init
%                     system doesn't get confused. 'derivobs',1
%
%
%     The additional fields needed with mean functions
%      meanFuncs    = mean functions to be used. Has to be a cell array
%                     with inputs as function handles to mean function
%                     used for. ex {@gpmf_squared}. Provide this before
%                     mean_prior.
%      mean_prior   = parameters of gaussian prior for weights of mean
%                     function's basis functions, {b,B} = N(b,B).
%                     Default (if not provided) b=0,B=0 so
%                     that the prior is vague and b and B
%                     values are not needed in the inference.
%                     Otherwise b is a row vector(1,n) and
%                     B matrix (n,n),
%                     where n matches with input dimension
%                     and the amount of mean functions used
%                     for ex. dim(x)=2, meanFuncs=squared+linear->n=4
%
%     The additional fields needed in sparse approximations are:
%      X_u          = Inducing inputs
%      Xu_prior     = prior structure for the inducing inputs. returned,
%                     for example, by prior_unif (the default)
%
%     The additional field required by PIC sparse approximation is:
%       tr_index    = The blocks for the PIC model. The value has to
%                     be a cell array of the index vectors appointing
%                     the data points into blocks. For example, if x
%                     is a matrix of data inputs then x(tr_index{i},:)
%                     are the inputs belonging to the i'th block.
%
%     The additional fields when the likelihood is not Gaussian
%     (lik ~='gaussian') are:
%       latent_method = Defines a method for marginalizing over
%                       latent values. Possible methods are 'MCMC',
%                       'Laplace' and 'EP' and they are initialized
%                       as following :
%
%                  'latent_method', {'MCMC', F, @fh_latentmc}
%                        F            = 1xn vector of latent values and
%                                       they are set as
%                        fh_latentmc  = Function handle to function
%                                       which samples the latent values,
%                                       e.g. @scaled_mh, @scaled_hmc
%
%                   'latent_method', {'Laplace', x, y(, z)}
%                        x  =  a matrix of inputs
%                        y  =  nx1 vector of outputs
%                        z  = optional observed quantity in triplet
%                             (x_i,y_i,z_i). Some likelihoods may use
%                             this. For example, in case of Poisson
%                             likelihood we have z_i=E_i, that is,
%                             expected  value for ith case.
%                   'latent_method', {'EP', x, y(, z)}
%                        x  =  a matrix of inputs
%                        y  =  nx1 vector of outputs
%                        z  = optional observed quantity in triplet
%                             (x_i,y_i,z_i). Some likelihoods may use
%                             this. For example, in case of Poisson
%                             likelihood we have z_i=E_i, that is,
%                             expected  value for ith case.
%
%	See also
%	GPINIT, GP2PAK, GP2UNPAK
%
%
%   References:
%    Qui�onero-Candela, J. and Rasmussen, C. E. (2005). A unifying
%    view of sparse approximate Gaussian process regression.
%    Journal of Machine Learning Research, 6(3):1939-1959.
%
%    Rasmussen, C. E. and Williams, C. K. I. (2006). Gaussian
%    Processes for Machine Learning. The MIT Press.
%
%    Snelson, E. and Ghahramani, Z. (2006). Sparse Gaussian process
%    using pseudo-inputs. In Weiss, Y., Sch�lkopf, B., and Platt,
%    J. (eds) Advances in Neural Information Processing Systems 18,
%    pp. 1257-1264.
%
%    Titsias, M. K. (2009). Variational Model Selection for Sparse
%    Gaussian Process Regression. Technical Report, University of
%    Manchester.
%
%    Vanhatalo, J. and Vehtari, A. (2008). Modelling local and
%    global phenomena with sparse Gaussian processes. Proceedings
%    of the 24th Conference on Uncertainty in Artificial
%    Intelligence,


% Copyright (c) 2006-2010 Jarno Vanhatalo

% This software is distributed under the GNU General Public
% License (version 2 or later); please refer to the file
% License.txt, included with the software, for details.

% allow use with or without init and set options
if nargin<1
    do='init';
elseif ischar(varargin{1})
    switch varargin{1}
        case 'init'
            do='init';varargin(1)=[];
        case 'set'
            do='set';varargin(1)=[];
        otherwise
            do='init';
    end
elseif isstruct(varargin{1})
    do='set';
else
    error('Unknown first argument');
end

if strcmp(do, 'init')
    if numel(varargin) < 4
        error('Not enough arguments')
    end
else
    if numel(varargin) < 2
        error('Not enough arguments')
    end
end

% Initialize a Gaussian process
if strcmp(do, 'init')
    gp.type = varargin{1};
    
    % Set likelihood.
    gp.lik = varargin{2};   % Remember to set the latent_method.
    
    % Set covariance functions into gpcf
    gpcf = varargin{3};
    for i = 1:length(gpcf)
        gp.cf{i} = gpcf{i};
    end
    
    % Set noise functions into noise
    if length(varargin) > 3
        gp.noise = [];
        gpnoise = varargin{4};
        for i = 1:length(gpnoise)
            gp.noise{i} = gpnoise{i};
        end
    else
        gp.noise = [];
    end
    
    % Default inference
    gp.infer_params='covariance+inducing+likelihood';
    
    % Initialize parameters
    gp.jitterSigma2=0;
    gp.p=[];
    
    switch gp.type
        case {'FIC' 'CS+FIC' 'DTC' 'VAR' 'SOR'}
            gp.X_u = [];
            gp.nind = [];
            gp.p.X_u = [];
        case {'PIC' 'PIC_BLOCK'}
            gp.X_u = [];
            gp.nind = [];
            gp.tr_index = {};
        case 'FULL'
            % do nothing
        otherwise
            error('Unknown type of GP!')
    end
    
    if length(varargin) > 4
        if mod(length(varargin),2) ~=0
            error('Wrong number of arguments')
        end
        % Loop through all the parameter values that are changed
        for i=5:2:length(varargin)-1
            switch varargin{i}
                case 'covariance'
                    % Set covariance functions into gpcf
                    gpcf = varargin{i+1};
                    for i = 1:length(gpcf)
                        gp.cf{i} = gpcf{i};
                    end
                case 'noise'
                    % Set noise functions into noise
                    gp.noise = [];
                    gpnoise = varargin{i+1};
                    for i = 1:length(gpnoise)
                        gp.noise{i} = gpnoise{i};
                    end
                case 'jitterSigma2'
                    gp.jitterSigma2 = varargin{i+1};
                case 'lik'
                    gp.lik = varargin{i+1};
                case 'type'
                    gp.type = varargin{i+1};
                case 'X_u'
                    gp.X_u = varargin{i+1};
                    gp.nind = size(varargin{i+1},1);
                    gp.p.X_u = prior_unif;
                case 'Xu_prior'
                    gp.p.X_u = varargin{i+1};
                case 'tr_index'
                    gp.tr_index = varargin{i+1};
                case 'infer_params'
                    gp.infer_params = varargin{i+1};
                case 'meanFuncs'
                    gp.mean.meanFuncs = varargin{i+1};
                    gp.mean.p.b=0;
                    gp.mean.p.B=0;
                    gp.mean.p.vague=1;
                case 'mean_p'
                    gp.mean.p.b=varargin{i+1}{1};
                    gp.mean.p.B=varargin{i+1}{2}(:)';
                    gp.mean.p.vague=0;
                case 'derivobs'
                    gp.derivobs=1;
                case 'latent_method'
                    gp.latent_method = varargin{i+1}{1};
                    switch varargin{i+1}{1}
                        case 'MCMC'
                            gp.latentValues = varargin{i+1}{2};
                            gp.fh_mc = varargin{i+1}{3};
                        case 'EP'
                            % Note in the case of EP, you have to give varargin{i+1} = {x, y, param}
                            gp.ep_opt.maxiter = 20;
                            gp.ep_opt.tol = 1e-6;
                            gp = gpep_e('init', gp, varargin{i+1}{2:end});
                            w = gp_pak(gp);
                            [e, edata, eprior, site_tau, site_nu] = gpep_e(w, gp, varargin{i+1}{2:end});
                            gp.site_tau = site_tau';
                            gp.site_nu = site_nu';
                        case 'Laplace'
                            gp.laplace_opt.maxiter = 20;
                            gp.laplace_opt.tol = 1e-12;
                            % use default choices for optimisation inside Laplace
                            % other choices can be used with setting
                            % gp.laplace_opt.optim_method before calling
                            % gp_init('set', gp, 'latent_method', {'Laplace', ...
                            switch gp.lik.type
                                case 'Student-t'
                                    % slower than stabilized-newton but more robust
                                    gp.laplace_opt.optim_method='lik_specific';
                                otherwise
                                    gp.laplace_opt.optim_method='newton';
                            end
                            switch gp.lik.type
                                case 'Softmax'
                                    gp = gpla_softmax_e('init', gp, varargin{i+1}{2:end});
                                    w = gp_pak(gp);
                                    [e, edata, eprior, f] = gpla_softmax_e(w, gp, varargin{i+1}{2:end});
                                otherwise
                                    gp = gpla_e('init', gp, varargin{i+1}{2:end});
                                    w = gp_pak(gp);
                                    [e, edata, eprior, f] = gpla_e(w, gp, varargin{i+1}{2:end});
                            end
                        otherwise
                            error('Unknown type of latent_method!')
                    end
                otherwise
                    error('Wrong parameter name!')
            end
        end
    end
    
    if ismember(gp.type,{'FIC' 'PIC' 'PIC_BLOCK' 'VAR' 'DTC' 'SOR'}) && isempty(gp.X_u)
        error(sprintf('Need to set X_u when using %s',gp.type))
    end
    
end

% Set the parameter values of covariance function
if strcmp(do, 'set')
    if mod(nargin,2) ~=0
        error('Wrong number of arguments')
    end
    gp = varargin{1};
    % Loop through all the parameter values that are changed
    for i=2:2:length(varargin)-1
        switch varargin{i}
            case 'covariance'
                % Set covariance functions into gpcf
                gpcf = varargin{i+1};
                for i = 1:length(gpcf)
                    gp.cf{i} = gpcf{i};
                end
            case 'noise'
                % Set noise functions into noise
                gp.noise = [];
                gpnoise = varargin{i+1};
                for i = 1:length(gpnoise)
                    gp.noise{i} = gpnoise{i};
                end
            case 'jitterSigma2'
                gp.jitterSigma2 = varargin{i+1};
            case 'likelih'
                gp.lik = varargin{i+1};
            case 'type'
                gp.type = varargin{i+1};
            case 'X_u'
                gp.X_u = varargin{i+1};
                gp.nind = size(varargin{i+1},1);
                gp.p.X_u = prior_unif;
            case 'Xu_prior'
                gp.p.X_u = varargin{i+1};
            case 'tr_index'
                gp.tr_index = varargin{i+1};
            case 'infer_params'
                gp.infer_params = varargin{i+1};
            case 'latent_method'
                gp.latent_method = varargin{i+1}{1};
                switch varargin{i+1}{1}
                    case 'MCMC'
                        gp.latentValues = varargin{i+1}{2};
                        gp.fh_mc = varargin{i+1}{3};
                    case 'EP'
                        % Note in the case of EP, you have to give varargin{i+1} = {x, y, param}
                        gp.ep_opt.maxiter = 20;
                        gp.ep_opt.tol = 1e-6;
                        gp = gpep_e('init', gp, varargin{i+1}{2:end});
                        w = gp_pak(gp);
                        [e, edata, eprior, site_tau, site_nu] = gpep_e(w, gp, varargin{i+1}{2:end});
                        gp.site_tau = site_tau';
                        gp.site_nu = site_nu';
                    case 'Laplace'
                        gp.laplace_opt.maxiter = 20;
                        gp.laplace_opt.tol = 1e-12;
                        if ~isfield(gp.laplace_opt,'optim_method') ...
                                | isempty(gp.laplace_opt.optim_method)
                            % If optim_method is not yet defined, use
                            % default choices for optimisation inside Laplace
                            switch gp.lik.type
                                case 'Student-t'
                                    % slower than stabilized-newton but more robust
                                    gp.laplace_opt.optim_method = 'lik_specific';
                                otherwise
                                    gp.laplace_opt.optim_method = 'newton';
                            end
                        end
                        switch gp.lik.type
                            case 'Softmax'
                                gp = gpla_softmax_e('init', gp, varargin{i+1}{2:end});
                                w = gp_pak(gp);
                                [e, edata, eprior, f] = gpla_softmax_e(w, gp, varargin{i+1}{2:end});
                            otherwise
                                gp = gpla_e('init', gp, varargin{i+1}{2:end});
                                w = gp_pak(gp);
                                [e, edata, eprior, f] = gpla_e(w, gp, varargin{i+1}{2:end});
                        end
                    otherwise
                        error('Unknown type of latent_method!')
                end
            otherwise
                error('Wrong parameter name!')
        end
    end
    
    if ismember(gp.type,{'FIC' 'PIC' 'PIC_BLOCK' 'VAR' 'DTC' 'SOR'}) && isempty(gp.X_u)
        error(sprintf('Need to set X_u when using %s',gp.type))
    end
end
end
