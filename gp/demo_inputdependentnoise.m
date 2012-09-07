%DEMO_INPUTDEPENDENTNOISE  Demonstration of input dependent-noise model using Gaussian
%               process prior
%
% Description
%       Uses toy data to demonstrate how inferring heteroscedastic noise
%       with input dependent noise model differs from standard noise models
%       (Gaussian, Student-t).
%
% Copyright (c) Ville Tolvanen 2011-2012
% 
% This software is distributed under the GNU General Public
% License (version 3 or later); please refer to the file
% License.txt, included with the software, for details.


%---------------------------------
% 1D Demonstration
%---------------------------------
stream0 = RandStream('mt19937ar','Seed',0);
prevstream = RandStream.setGlobalStream(stream0);
close all;
% x = 100*rand([40 1]);
n =150;
nt = 150;
x=linspace(-100,200,n)';
% xt = linspace(0,100, nt)';
xt=x;
% xt=linspace(-10,10,nt);
% x=linspace(0,1,n);
% x=linspace(-5,5,n);
% f1=betapdf(x,3,10);
% f1 = 0.3.*x.^3+0.20.*x.^2+5.*x+1;
% f1 = 0.001*randn(size(x));
f1 = [5.*sin(-3+0.2.*x(1:ceil(0.23*n))); 20*sin(0.1*x(ceil(0.23*n)+1:ceil(0.85*n))); 5.*sin(2.8+0.2.*x(ceil(0.85*n)+1:end))];
% f1 = 10*sin(0.03*x);
% f2 = 100*sin(x).^2;
f2 = 100*norm_pdf(x,110,15) + 100*norm_pdf(x,-10,15);
% f22 = 150*norm_pdf(xt, 100, 20);
% f2 = 0.1*x;
% f2 = -0.1.*x;
% f1 = sin(0.025.*x);
sigma2 = 0.5;



x=x-mean(x); x=x./std(x);
xt=xt-mean(xt); xt=xt./std(xt);
f1 = f1-mean(f1); f1=f1./std(f1);
% f2 = f2-mean(f2); f2=f2./std(f2);

y = f1 + sqrt((sigma2.*exp(f2))).*randn(size(x));
yt= f1;
x=x(:); y=y(:); xt=xt(:);


% Create the covariance functions
pl = prior_logunif();
pm = prior_logunif(); 
% pl = prior_t('s2',20);
% pm = prior_t('s2',20); 
gpcf1 = gpcf_sexp('lengthScale', 0.5, 'magnSigma2', 0.1);
gpcf2 = gpcf_sexp('lengthScale', 1, 'magnSigma2', 0.1);
% gpcf2 = gpcf_neuralnetwork('weightSigma2', [1.2 2.1], 'biasSigma2', 0.8, 'weightSigma2_prior', pl, 'biasSigma2_prior', pm);
gpcf1 = gpcf_sexp(gpcf1, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);
gpcf2 = gpcf_sexp(gpcf2, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);
% gpcf2 = gpcf_sexp(gpcf2, 'lengthScale_prior', prior_fixed(), 'magnSigma2_prior', prior_fixed());

% gpcf1 = gpcf_neuralnetwork('weightSigma2', [1], 'biasSigma2', 1, 'weightSigma2_prior', pl, 'biasSigma2_prior', pm);
% gpcf2 = gpcf_neuralnetwork('weightSigma2', [1.2], 'biasSigma2', 0.8, 'weightSigma2_prior', pl, 'biasSigma2_prior', pm);

% pm = prior_sqrtunif();

% Create the likelihood structure. Dont set prior for sigma2 if covariance
% function magnitude for noise process has prior.
lik = lik_inputdependentnoise('sigma2', 0.1, 'sigma2_prior', prior_fixed());

% NOTE! if Multible covariance functions per latent is used, define
% gp.comp_cf as follows:
% gp = gp_set(..., 'comp_cf' {[1 2] [5 6]};
gp = gp_set('lik', lik, 'cf', {gpcf1 gpcf2}, 'jitterSigma2', 1e-9, 'comp_cf', {[1] [2]});

% Set the approximate inference method to Laplace
gp = gp_set(gp, 'latent_method', 'Laplace');
% For more complex problems, maxiter in latent_opt should be increased.
% gp.latent_opt.maxiter=1e6;

% Set the options for the scaled conjugate optimization
opt=optimset('TolFun',1e-4,'TolX',1e-4,'Display','iter','MaxIter',100,'Derivativecheck','on');

% Optimize with the scaled conjugate gradient method
% gp=gpla_nd_e('init',gp); gp.lik.structW=false;gp.lik.fullW=false;
gp=gp_optim(gp,x,y,'opt',opt);

% make prediction to the data points
[Ef, Varf,lpyt] = gp_pred(gp, x, y, xt, 'yt', yt);
Ef=Ef(:); %Varf=diag(Varf);
Ef11 = Ef(1:nt);
Ef12 = Ef(nt+1:end);
fprintf('mlpd inputdependentnoise: %.2f\n', mean(lpyt));

% Gaussian for comparison
opt=optimset('TolFun',1e-4,'TolX',1e-4,'Display','iter','MaxIter',100,'Derivativecheck','off');
lik2 = lik_gaussian();
gp2 = gp_set('lik', lik2, 'cf', gpcf1, 'jitterSigma2', 1e-9);
gp2 = gp_optim(gp2,x,y,'opt',opt);
[Ef2, Varf2, lpyt2] = gp_pred(gp2, x, y, xt,'yt',yt);
fprintf('mlpd gaussian: %.2f\n', mean(lpyt2));

% Student-t for comparison
lik=lik_t();
gp3=gp_set('lik', lik, 'cf', gpcf1, 'jitterSigma2', 1e-9);
opt=optimset('TolFun',1e-4,'TolX',1e-4,'Display','iter','MaxIter',100,'Derivativecheck','off');
gp3 = gp_set(gp3, 'latent_method', 'Laplace');
gp3=gp_optim(gp3,x,y,'opt',opt);
[Ef3, Varf3,lpyt3] = gp_pred(gp3, x, y, xt, 'yt', yt);
fprintf('mlpd student-t: %.2f\n', mean(lpyt3));


figure;
s2=gp.lik.sigma2;
subplot(3,1,1),plot(xt,Ef(1:nt),'b',xt,Ef(1:nt)+1.*sqrt(diag(Varf(1:nt,1:nt))),'r',...
xt,Ef(1:nt)-1.*sqrt(diag(Varf(1:nt,1:nt))),'r', x, f1, 'k'),ylim([-5 5]), title('Inputnoise');


% Compare to gaussian with standard noise
subplot(3,1,2),plot(xt, Ef2,'b',xt,Ef2+1.*sqrt(Varf2),'r',...
xt,Ef2-1.*sqrt(Varf2),'r', x, f1, 'k'), ylim([-5 5]), title('Gaussian noise')


subplot(3,1,3),plot(xt, Ef3,'b',xt,Ef3+1.*sqrt(Varf3),'r',...
xt,Ef3-1.*sqrt(Varf3),'r', x, f1, 'k'), ylim([-5 5]), title('Student-t noise')

figure, plot(x,y,'bo',xt,Ef11, xt, Ef2, xt, Ef3, x, f1), legend('Observations','Inputdependent', 'Gaussian', 'Student-t', 'Real', 'Location', 'NorthWest');

figure, plot(xt, s2.*exp(Ef12), '-b',x, sigma2.*exp(f2), '-k', xt, s2.*exp(Ef12 + 2.*sqrt(diag(Varf(nt+1:end, nt+1:end)))), '-r', xt,s2.*exp(Ef12 - 2.*sqrt(diag(Varf(nt+1:end, nt+1:end)))), '-r'), legend('Predicted noise variance', 'Real noise variance');

% pause
%------------------------------------
% 2D Demonstration
%------------------------------------
stream0 = RandStream('mt19937ar','Seed',0);
prevstream = RandStream.setGlobalStream(stream0);

% Create data from two 2 dimensional gaussians
nt=10;
n=700;
x=[-3+6*rand(0.25*n,1) -3+6*rand(0.25*n,1);-1.5+3*rand(0.75*n,1) -1.5+3*rand(0.75*n,1)];
mu=[0 0];
S=[0.2 0;0 0.2];
sigma2=0.1;
[x1,x2]=meshgrid(linspace(-1,2,nt), linspace(-1,2,nt));
xt=[x1(:) x2(:)];
f1t=10*mnorm_pdf(xt,mu,S) + 20*mnorm_pdf(xt,mu+[1.5 1.5], [0.5 0;0 0.5]);
f2t=20*mnorm_pdf(xt,mu, [0.9 0;0 0.9]);
yt=f1t;
f1 = 10*mnorm_pdf(x,mu, S) + 20*mnorm_pdf(x,mu+[1.5 1.5], [0.5 0;0 0.5]);
f2 = 20*mnorm_pdf(x,mu, [0.9 0;0 0.9]);

y=f1+randn(size(x,1),1).*sqrt(sigma2.*exp(f2));

% plot3(x(:,1), x(:,2), y,'.')

pl = prior_logunif();
pm = prior_logunif(); 
gpcf1 = gpcf_sexp('lengthScale', [1 1.01], 'magnSigma2', 1);
gpcf2 = gpcf_sexp('lengthScale', [1 1.01], 'magnSigma2', 0.1);
gpcf1 = gpcf_sexp(gpcf1, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);
gpcf2 = gpcf_sexp(gpcf2, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);

lik=lik_inputdependentnoise('sigma2', 0.1, 'sigma2_prior', prior_fixed());

gp=gp_set('lik', lik, 'cf', {gpcf1 gpcf2}, 'jitterSigma2', 1e-6, 'comp_cf', {[1] [2]});
gp = gp_set(gp, 'latent_method', 'Laplace');
opt=optimset('TolFun',1e-4,'TolX',1e-4,'Display','iter','MaxIter',100,'Derivativecheck','off');
gp=gp_optim(gp,x,y,'opt',opt);
% Increase maxiter for predictions in case of slow convergence
gp.latent_opt.maxiter=1e6;
[Ef,Varf,lpyt]=gp_pred(gp,x,y,xt, 'yt',yt);
Ef=Ef(:);% Varf=[diag(squeeze(Varf(1,1,:))), zeros(100); zeros(100) diag(squeeze(Varf(2,2,:)))];
fprintf('mlpd inputdependentnoise: %.2f\n', mean(lpyt));

lik2 = lik_gaussian('sigma2', sigma2);
gp2 = gp_set('lik', lik2, 'cf', gpcf1, 'jitterSigma2', 1e-6);
gp2 = gp_optim(gp2,x,y,'opt',opt);
[Ef2,Varf2,lpyt2]=gp_pred(gp2,x,y,xt,'yt',yt);
fprintf('mlpd gaussian: %.2f\n', mean(lpyt2));

lik3=lik_t('sigma2', sigma2);
gp3=gp_set('lik', lik3, 'cf', gpcf1, 'jitterSigma2', 1e-6, 'latent_method', 'Laplace');
gp3=gp_optim(gp3,x,y,'opt',opt);
[Ef3,Varf3,lpyt3]=gp_pred(gp3,x,y,xt,'yt',yt);
fprintf('mlpd student-t: %.2f\n', mean(lpyt3));

s2=gp.lik.sigma2;
figure,subplot(3,1,1),mesh(x1,x2,reshape(f1t,size(x1))),hold on, plot3(xt(:,1),xt(:,2), Ef(1:size(xt,1)), '*'), title('Inputdependentnoise');
colormap hsv
alpha(.4)
subplot(3,1,2),mesh(x1,x2,reshape(f1t,size(x1))),hold on, plot3(xt(:,1),xt(:,2), Ef2(1:size(xt,1)), '*');colormap hsv, alpha(.4), title('Gaussian noise');
subplot(3,1,3),mesh(x1,x2,reshape(f1t,size(x1))),hold on, plot3(xt(:,1),xt(:,2), Ef3(1:size(xt,1)), '*');colormap hsv, alpha(.4), title('Student-t noise');

figure,mesh(x1,x2,sigma2.*exp(reshape(f2t,size(x1)))),hold on, plot3(xt(:,1),xt(:,2), s2.*exp(Ef(size(xt,1)+1:end)), '*'); title('Real noise versus predicted noise');
colormap hsv
alpha(.4)

%--------------------------------------------
% Demonstration without heteroscedastic noise
%--------------------------------------------
stream0 = RandStream('mt19937ar','Seed',0);
prevstream = RandStream.setGlobalStream(stream0);


n =200;
nt = 200;
x = linspace(-100,200, n)';
% x=sort(x);
xt = linspace(-100,200, n)';
f1 = [5.*sin(-3+0.2.*x(1:ceil(0.23*n))); 20*sin(0.1*x(ceil(0.23*n)+1:ceil(0.85*n))); 5.*sin(2.8+0.2.*x(ceil(0.85*n)+1:end))];
sigma2 = 1;
% yt= [sin(0.1.*xt(1:ceil(0.25*n))); 10*sin(0.1*xt(ceil(0.25*n)+1:ceil(0.75*n))); sin(0.1.*xt(ceil(0.75*n)+1:end))];

% xt=linspace(-100,200,nt);

x=x-mean(x); x=x./std(x);
xt=xt-mean(xt); xt=xt./std(xt);
f1 = f1-mean(f1); f1=f1./std(f1);

y = f1 + sqrt(sigma2).*randn(size(x));yt=f1;
x=x(:); y=y(:); xt=xt(:);

% x=x-mean(x); x=x./std(x);
% y=y-mean(y); y=y./std(y);
% xt=xt-mean(xt); xt=xt./std(xt);
% f1 = f1-mean(f1); f1=f1./std(f1);
% f2 = f2-mean(f2); f2=f2./std(f2);

% Create the covariance functions
% pl = prior_logunif();
% pm = prior_logunif(); 
pl = prior_t('s2',20);
pm = prior_t('s2',20); 
gpcf1 = gpcf_sexp('lengthScale', 0.5, 'magnSigma2', 0.5);
gpcf2 = gpcf_sexp('lengthScale', 0.5, 'magnSigma2',0.1);
gpcf1 = gpcf_sexp(gpcf1, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);
gpcf2 = gpcf_sexp(gpcf2, 'lengthScale_prior', pl, 'magnSigma2_prior', pm);

% Create the the model
lik = lik_inputdependentnoise('sigma2', 0.1, 'sigma2_prior', prior_fixed());
gp = gp_set('lik', lik, 'cf', {gpcf1 gpcf2}, 'jitterSigma2', 1e-9, 'comp_cf', {[1] [2]});

% Set the approximate inference method to Laplace
gp = gp_set(gp, 'latent_method', 'Laplace');
opt=optimset('TolFun',1e-4,'TolX',1e-4,'Display','iter','MaxIter',100,'Derivativecheck','off');

% if flat priors are used, there might be need to increase
% gp.latent_opt.maxiter for laplace algorithm to converge properly

% gp.latent_opt.maxiter=1e6;

gp=gp_optim(gp,x,y,'opt',opt);

[Ef, Varf,lpyt] = gp_pred(gp, x, y, xt,'yt',yt);
Ef=Ef(:);% Varf=[diag(squeeze(Varf(1,1,:))), zeros(n); zeros(n) diag(squeeze(Varf(2,2,:)))];
Ef11 = Ef(1:nt);
Ef12 = Ef(nt+1:end);
fprintf('mlpd inputdependentnoise: %.2f\n', mean(lpyt));

% Set the options for the scaled conjugate optimization
% opt.lambda=1e4;
lik2 = lik_gaussian();
gp2 = gp_set('lik', lik2, 'cf', gpcf1, 'jitterSigma2', 1e-6);
gp2 = gp_optim(gp2,x,y,'opt',opt);
[Ef2, Varf2, lpyt2] = gp_pred(gp2, x, y, xt,'yt',yt);
fprintf('mlpd gaussian: %.2f\n', mean(lpyt2));

lik=lik_t();
gp3=gp_set('lik', lik, 'cf', gpcf1, 'jitterSigma2', 1e-6);
gp3 = gp_set(gp3, 'latent_method', 'Laplace');
gp3=gp_optim(gp3,x,y,'opt',opt);
[Ef3, Varf3,lpyt3] = gp_pred(gp3, x, y, xt,'yt',yt);
fprintf('mlpd student-t: %.2f\n', mean(lpyt3));

figure;
s2=gp.lik.sigma2;
subplot(3,1,1),plot(x,y,'bo',xt,Ef(1:nt),'b',xt,Ef(1:nt)+1.*sqrt(diag(Varf(1:nt,1:nt))),'r',...
xt,Ef(1:nt)-1.*sqrt(diag(Varf(1:nt,1:nt))),'r', x, f1, 'k'), title('Inputnoise');
% figure;
subplot(3,1,2),plot(x,y,'bo', xt, Ef2,'b',xt,Ef2+1.*sqrt(Varf2),'r',...
xt,Ef2-1.*sqrt(Varf2),'r', x, f1, 'k'), title('Gaussian noise')
% figure;
subplot(3,1,3),plot(x,y,'bo', xt, Ef3,'b',xt,Ef3+1.*sqrt(Varf3),'r',...
xt,Ef3-1.*sqrt(Varf3),'r', x, f1, 'k'), title('Student-t noise')
% figure, plot(xt,Ef11, xt, Ef2, xt, Ef3, x, f1), legend('Inputdependent', 'Gaussian', 'Student-t', 'Real', 'Location', 'NorthWest');