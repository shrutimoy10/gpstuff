function [c,bb] = hcs(crit,y,z,t,varargin)
% [C, BB] = HCS(CRIT,Y,Z,T,OPTIONS)
%
% Description
%
% Given criteria vector CRIT, observed time vector Y, censoring indicator 
% column vector Z  at time t (0=exact, 1=censored) and t returns Harrel's C at point t and it's
% estimated density using Bayesian Bootstrap method
%
% OPTIONS
%      rsubstream    - number of a random stream to be used for
%                   simulating dirrand variables. This way
%                   same simulation can be obtained for different
%                   models. See doc RandStream for
%                   more information.     

ip=inputParser;
ip.addRequired('crit',@(x) ~isempty(x) && isreal(x) && all(isfinite(x(:))))
ip.addRequired('y', @(x) isreal(x) && all(isfinite(x(:))))
ip.addRequired('z', @(x) isreal(x) && all(isfinite(x(:))))
ip.addRequired('t', @(x) isreal(x) && all(isfinite(x(:))))
ip.addParamValue('rsubstream',0,@(x) isreal(x) && isscalar(x) && isfinite(x) && x>0)
ip.parse(crit,y,z,t,varargin{:})
rsubstream=ip.Results.rsubstream;

  n=size(crit,1);
  comp=bsxfun(@times,bsxfun(@and,bsxfun(@lt,y,y'),y<t),z==0);
  conc=bsxfun(@gt,crit,crit').*comp;
  c=sum(conc(:))./sum(comp(:));
  
  if nargin<5
      for i=1:100
           qr=dirrand(n);
           qqr=bsxfun(@times,qr,qr');
           bb(i,1)=sum(sum(conc.*qqr))./sum(sum(comp.*qqr));
      end
  end
      if rsubstream>0
      stream = RandStream('mrg32k3a');

        if str2double(regexprep(version('-release'), '[a-c]', '')) < 2012
            prevstream=RandStream.setDefaultStream(stream);
        else
            prevstream=RandStream.setGlobalStream(stream);
        end
            stream.Substream = rsubstream;

           for i=1:100
           qr=dirrand(n);
           qqr=bsxfun(@times,qr,qr');
           bb(i,1)=sum(sum(conc.*qqr))./sum(sum(comp.*qqr));
           end

        if str2double(regexprep(version('-release'), '[a-c]', '')) < 2012
            RandStream.setDefaultStream(prevstream);
        else
            RandStream.setGlobalStream(prevstream);
        end;
      end
end
