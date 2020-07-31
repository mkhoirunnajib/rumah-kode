function [PD,D] = distfitter(data,options)
%DISTFITTER Data Distribution Fitting Program
%   The use and modification of functions is welcome without the need for 
%   permission from the source on the condition that it displays 
%   the copyright.
%   This program will identify the distribution of data using several 
%   parametric distributions, viz 
%         - Extreme Value
%         - Generalized Extreme Value
%         - Logistic
%         - Normal
%         - Exponential
%         - Gamma
%         - Inverse Gaussian
%         - Log-logistic
%         - Log-normal
%         - Weibull
%   You can choose the best distribution using several test parameters, 
%   such as:
%         - Negative Log Likelihood
%         - Kolmogorov-Smilnov Error
%         - R-square
%         - chi-square
%         - Root Mean Squared Error
% 
%   THE OUTPUT:
%   PD = distfitter(DATA) only shows all the results of the identification of 
%   the distribution of data.
% 
%   [PD,D] = distfitter(...) also displays a D data structure with
%   fields:
%        Field Name         Description
%       'DistName'          Distribution Name
%       'NLogL'             Negative Log Likelihood
%       'KSE'               Kolmogorov-Smilnov Error
%       'R2'                R Square
%       'x2'                Chi Square
%       'RMSE'              Root Mean Square Error 
%       'ParamNames'        Parameter Names
%       'ParamDercription'  Parameter Descriptions
%       'Params'            Parameter Values
%   
%   THE INPUT
%   [...] = distfitter(DATA) fits the probability distribution to
%   the data. Data can be a column/row or matrice. Probability distribution
%   sorted by NLogL value with no PDF or CDF plot.
%   [...] = distfitter(DATA,OPTIONS) fits the probability distribution to
%   the data with more options. Data can be a column/row or matrice. 
%   The option must be a structure array with field as
%       Name            Value
%      option.sortby    {'NLogL','KSE','R2','x2','RMSE'} Default 'NLogL'
%      option.graph     {'pdf','cdf'} Default 'no plot'
%      option.result    Number of PD that showed on PDF/CDF plot. Default 4
%      option,nbins     Number of empiric PDF plot bin. Default 50
%
%   EXAMPLES:
%     data = random('normal',2,1,100);
%     options.sortby = 'rmse';
%     options.graph = 'pdf';
%     options.result = 2;
%     [pd,d] = distfitter(data,options);
% 
%   Copyright (c) 2020 
%   Mohamad Khoirun Najib
%   
fprintf('Running data distribution fitter\n')
sortbylist = {'nlogl','kse','r2','x2','rmse'};
graphlist = {'pdf','cdf'};
% options set
if nargin>1
    if isfield(options,'sortby')
        if ismember(lower(options.sortby),sortbylist)
            sortby = lower(options.sortby);
        else
            error('ERROR: Try options.sortby for NlogL, KSE, R2, X2, or RMSE')
        end
    else
        sortby = 'nlogl';
    end
    if isfield(options,'graph')
        if ismember(lower(options.graph),graphlist)
            graph = lower(options.graph);
        else
            error('ERROR: Try options.graph for pdf or cdf')
        end
    else
        graph= 'no plot';
    end
    if isfield(options,'result')
        if isnumeric(options.result)
            value = options.result;
        else
            error('ERROR: options.result must be a number')
        end
    else
        value = 4;
    end
    if isfield(options,'nbins')
        if isnumeric(options.nbins)
            nbins = options.nbins;
        else
            error('ERROR: options.nbins must be a number')
        end
    else
        nbins = 50;
    end
end

fprintf(['     1) Sort by         : ',sortby,'\n',...
         '     2) Graph           : ',graph,'\n',...
         '     3) Result on Graph : %g\n',...
         '     4) Empiric bins    : %g\n'],...
         value,nbins)
% Fitting Process
data=data(:);n=numel(data);
DistName = {'ExtremeValue','GeneralizedExtremeValue',...
    'Logistic','Normal','Exponential','Gamma','Inverse Gaussian','Log logistic',...
    'Lognormal','Weibull'};
typedata = sort(data);
if typedata(1)<=0;typedata='negatif';td = 'real';else;typedata='positif';td='positive';end
if typedata=='positif';ndist = length(DistName);else;ndist = 4;end
fprintf(['     5) Data set        : ',td,'\n'])

for i = 1:ndist
    warning('');warnMsg=[];warnId=[];
    PD{i}=fitdist(data,DistName{i});
    [warnMsg,~]=lastwarn;
    warning('off')
    if ~isempty(warnMsg);st=1;end
    NLL(i)=negloglik(PD{i});
end
% Uji
for i = 1:length(PD)
    D(i).DistName=DistName{i};
    D(i).NLogL=NLL(i);
    [KSE,R2,x2,rmse]=finderror(data,PD{i});
    D(i).KSE=KSE;
    D(i).R2=R2;
    D(i).x2=x2;
    D(i).RMSE=rmse;
    D(i).ParamNames=PD{i}.ParamNames;
    D(i).ParamDescription=PD{i}.ParamDescription;
    D(i).Params=PD{i}.Params;
end
% Sorting
[~,sortin]=ismember(sortby,sortbylist);
indx1=1:length(D);
if sortin == 1
    [~,indx1]=sort([D.NLogL]);
elseif sortin == 2
    [~,indx1]=sort([D.KSE]);
elseif sortin == 3
    [~,indx1]=sort([D.R2],'descend');
elseif sortin == 4
    [~,indx1]=sort([D.x2]);
elseif sortin == 5
    [~,indx1]=sort([D.RMSE]);
else
    error('COCOKAN:Input Argument:Sortby')
end
% Sort
D=D(indx1); PD = PD(indx1);
D=D';PD=PD';

fprintf(['The closest distributions is ',D(1).DistName,'\n'])
% Ploting Graphics PDF or CDF
if ismember(graph,graphlist)
numdist = min([value,5,length(PD)]);
if graph=='pdf'
    pdf_plot(data,nbins);
    xi = linspace(min(data),max(data),100);
    if value>0
        nkm={'r-','k-','y-.',':','r--'};
        for i=1:numdist
            yi = pdf(PD{i},xi);hold on
            h(i) = plot(xi(:),yi(:),nkm{i},'LineWidth',2);
        end
        lgd=legend(h,{D(1:numdist).DistName},'Location','Best');
    end
    hold off;grid on
elseif graph=='cdf'
    [fi,xi] = ecdf(data);plot(xi,fi,'m','LineWidth',1)
    if value>0
        nkm={'k-','-.','r--',':','b--'};
        for i=1:numdist 
            hold on
            yi=cdf(PD{i},xi(:));
            plot(xi(:),yi(:),nkm{i},'LineWidth',2);
        end
        lgd=legend(['Empirik',{D(1:numdist).DistName}],'Location','Best');
    end
    hold off
    grid on
end
end
% ============== Nested Function ============
function [kse,R2,x2,rmse] = finderror(data,pd)
[fi,xi]=ecdf(data);
fhat = cdf(pd,xi);
kse  = max(abs(fhat-fi));
fbar = mean(fhat);
f1   = sum((fhat-fbar).^2);
f2   = sum((fi-fhat).^2);
R2   = f1/(f1+f2);
x2   = sum((fi-fhat).^2./abs(fhat));
rmse = sqrt(mean((fi-fhat).^2));
end
function [xi,fi]=pdf_plot(data,nbins)
xi = linspace(min(data),max(data),nbins);
dx = mean(diff(xi));
fi = histc(data,xi-dx);
fi = fi./sum(fi)./dx;
bar(xi,fi,'FaceColor',[0.5 1 1],'EdgeColor',[0 0.5 1])
title('Probability Density Function');
grid on
end
end