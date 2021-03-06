function result=frat(ldata,fwhm2,cdata)
%     FOURIER-RATIO DECONVOLUTION USING EXACT METHOD (A)
%     WITH LEFT SHIFT BEFORE FORWARD TRANSFORM.
%     RECONVOLUTION FUNCTION R(F) IS EXP(-X*X) .
%     DATA IS READ IN FROM NAMED INPUT FILES
%     OUTPUT DATA APPEARS in a named output file as nn x-y PAIRS
% 
% Details in R.F.Egerton: EELS in the Electron Microscope, 3rd edition, Springer 2011


%Read low-loss data from input file

data = [ldata.x, ldata.y];
size(data)
nd = length(data);
nn = 2^fix(log2(nd)+1); 

%set arrays to zero
lldata=zeros(1,nn);
e=zeros(1,nn); 
d=zeros(1,nn);


%assign data to arrays
e(1:nd) = data(:,1);
lldata(1:nd) = data(:,2);

epc=(e(5)-e(1))/4;
back = sum(lldata(1:5));
%     Set BACK=0. if zero-loss tail dominates first 5 channels
back = back + sum(lldata(1:5))/5;

%     Find zero-loss channel:
nz = find(lldata==max(lldata),1,'first');

%     Find minimum in J(E)/E to estimate zero-loss sum A0:
for i=nz:nd;
    if(lldata(i+1)/(i-nz+1)>lldata(i)/(i-nz))
        break;
    end;
    nsep=i;
end;
sum_nsep = sum(lldata(1:nsep));
a0 = sum_nsep - back*(nsep);
nfin = nd-nz+1;

%     TRANSFER SHIFTED DATA TO ARRAY d:
d(1:nfin) = lldata(nz:nd)-back;

%     EXTRAPOLATE THE SPECTRUM TO ZERO AT channel nn:
a1 = sum(d(nfin-9:nfin-5));
a2 = sum(d(nfin-4:nfin));
r = 2*log((a1+0.2)/(a2+0.1))/log((nd-nz)/(nd-nz-10));
dend = d(nfin)*((nfin-1)/(nn-2-nz))^r;

cosb = 0.5 - 0.5.*cos(pi.*[0:nn-nfin]./(nn-nfin-nz-1));
d(nfin:nn)= d(nfin).*((nfin-1)./[nfin-1:nn-1]).^r - cosb.*dend; 

%     Compute total area:
at = sum(d(1:nn)); %This may be needed when calculating 'gauss'

%     Add left half of Z(E) to end channels in the array D(J):

d(nn+2-nz:nn) = lldata(1:nz-1) - back;


fwhm1=0.9394*a0/d(1)*epc;

fwhm2=fwhm2/epc;

%Read CORE-loss data from input file
% fidin=fopen(cfile);
% data = fscanf(fidin,'%g%*c %g',[2,nc]);
% fclose(fidin);
size(cdata.x)
size(cdata.y)
data = [cdata.x', cdata.y];
nc = length(data);

e(1:nc) = data(:,1);
c(1:nc) = data(:,2);
epc=(e(5)-e(1))/4;

%     EXTRAPOLATE THE SPECTRUM TO ZERO AT channel nn:
a1 = sum(c(nc-9:nc-5));
a2 = sum(c(nc-4:nc));
r = 2*log((a1+0.2)/(a2+0.1))/log(e(nc)/e(nc-9));
cend = a2/5*(e(nc-2)/(e(1)+epc*(nn-1)))^r;
cosb = 0.5 - 0.5.*cos(pi.*[0:nn-nc]./(nn-nc));
c(nc:nn)= a2./5.*(e(nc-2)./(e(1)+epc.*([nc-3:nn-3]))).^r - cosb.*cend; 
fprintf(1,'%0.15g %0.15g %0.15g %0.15g %0.15g %0.15g \n', r,cend,c(nc),c(nn),a1,a2);

%     WRITE background-stripped CORE PLURAL SCATTERING DISTRIBUTION TO frat-psd.dat:
% fidout=fopen('Frat.psd','w');
eout = e(1)+epc.*[-1:nn-2];
% cpout = real(c(1:nn));
% fprintf(fidout,'%8.15g %8.15g \n',[eout;cpout]);
% fclose(fidout);

d = conj(fft(d,nn));
c = conj(fft(c,nn));

%     Process the Fourier coefficients:
d = d + 1e-10;
c = c + 1e-10;
x = [0:(nn/2-1) (nn/2):-1:1];
x = 1.887 .* fwhm2 .* x ./ nn;
gauss = a0 ./ 2.718.^(x.^2)./nn;  

%Replace 'a0' by 'at' above to give equal AREAS in SSD and PSD. 
d = gauss.* c ./ d;

d = fft(d,nn);

csout = real(d(1:nn));

result.x=eout;
result.y=csout;

% % Plot
% figure;
% plot(eout,csout,'r');
% hold on;
% plot(eout,cpout,'g');
% legend('SSD','PSD');
% title('Frat Output','FontSize',12);
% xlabel('Energy Loss [eV]');
% ylabel('Count');
% hold off;
end

