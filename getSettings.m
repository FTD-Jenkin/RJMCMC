function [settings, priorsARMA, proposalsARMA] = getSettings()
%Returns structure containing the settings, the prior function handel, the proposal function handle, as
%well as the Likelihood function

%Priors,

settings.draws = 1500000;
settings.useData = 'TrendBreakFDIFF';
settings.pMax = 10;
settings.qMax = 10;
settings.burnIn = 500000;
settings.saveProposals = 1;

%CHANGE THIS TO HANDLE
settings.likelihoodFunction = 1;

%Setup Priors. Array of struct
priorsARMA(1) = struct();

%Function handles for prior distributions, autoregressive (moving average)
%(inverse) partial autocorrelations
priorsARMA(1).priorARParam1 = -1 + eps;
priorsARMA(1).priorARParam2 = 1 - eps;
priorsARMA(1).priorAR = @(x) unifpdf(x,priorsARMA(1).priorARParam1,priorsARMA(1).priorARParam2);

priorsARMA(1).priorMAParam1 = -1 + eps;
priorsARMA(1).priorMAParam2 = 1 - eps;
priorsARMA(1).priorMA = @(x) unifpdf(x,priorsARMA(1).priorMAParam1,priorsARMA(1).priorMAParam2);

priorsARMA(1).priorSigmaEParam1 = 1;
priorsARMA(1).priorSigmaEParam2 = 1;
priorsARMA(1).priorSigmaE = ...
    @(x) (x>0)*(priorsARMA(1).priorSigmaEParam2^priorsARMA(1).priorSigmaEParam1...
    / gamma(priorsARMA(1).priorSigmaEParam1) * x^(-priorsARMA(1).priorSigmaEParam1 - 1)...
    * exp(-priorsARMA(1).priorSigmaEParam2/x));

priorsARMA(1).priorPParam1 = settings.pMax;
priorsARMA(1).priorP = @(x) unidpdf(x + 1,priorsARMA(1).priorPParam1 + 1);

priorsARMA(1).priorQParam1 = settings.qMax;
priorsARMA(1).priorQ = @(x) unidpdf(x + 1,priorsARMA(1).priorQParam1 + 1);

%Setup proposal distributions for ARMA Coefficients and respective standard
%deviation. 
proposalsARMA(1) = struct();

%Proposals are always centered around the current value of the respective
%parameters (PAC). Proposals have to be supplied in two ways: Firstly, the
%actual proposal, i.e. a function returning the sampled value for the
%parameters. Secondly, the evaluation of the PDF at the proposed value
%with the distribution centered around the current state.
%Between Model Moves (If model changes)
proposalsARMA(1).proposalARParam1Between = 0.045;
proposalsARMA(1).proposalARBetween = @(mu) vectorizedRTNorm(-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1Between);
proposalsARMA(1).evaluateProposalARBetween = @(x, mu) evaluateTruncatedNormalPDF(x,-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1Between);

proposalsARMA(1).proposalMAParam1Between = 0.045;
proposalsARMA(1).proposalMABetween = @(mu) vectorizedRTNorm(-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1Between);
proposalsARMA(1).evaluateProposalMABetween = @(x, mu) evaluateTruncatedNormalPDF(x,-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalMAParam1Between);


%Within Model Moves (Model remains the same)
proposalsARMA(1).proposalARParam1 = 0.02;
proposalsARMA(1).proposalARParam2 = 0/0;
proposalsARMA(1).proposalARParam3 = 0/0;
proposalsARMA(1).proposalARParam4 = 0/0;
proposalsARMA(1).proposalAR = @(mu) vectorizedRTNorm(-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1);
proposalsARMA(1).evaluateProposalAR = @(x, mu) evaluateTruncatedNormalPDF(x,-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1);

proposalsARMA(1).proposalMAParam1 = 0.02;
proposalsARMA(1).proposalMAParam2 = 0/0;
proposalsARMA(1).proposalMAParam3 = 0/0;
proposalsARMA(1).proposalMAParam4 = 0/0;
proposalsARMA(1).proposalMA = @(mu) vectorizedRTNorm(-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalARParam1);
proposalsARMA(1).evaluateProposalMA = @(x, mu) evaluateTruncatedNormalPDF(x,-1,1,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalMAParam1);

proposalsARMA(1).proposalSigmaEParam1 = 0.04;
proposalsARMA(1).proposalSigmaEParam2 = 0/0;
proposalsARMA(1).proposalSigmaEParam3 = 0/0;
proposalsARMA(1).proposalSigmaEParam4 = 0/0;
proposalsARMA(1).proposalSigmaE = @(mu) vectorizedRTNorm(0,1000,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalSigmaEParam1);
proposalsARMA(1).evaluateProposalSigmaE = @(x, mu) evaluateTruncatedNormalPDF(x,0,1000,mu,ones(size(mu,1),1)*proposalsARMA(1).proposalSigmaEParam1);

%Proposals AR-Order
proposalsARMA(1).proposalPParam1 = settings.pMax;
proposalsARMA(1).proposalPParam2 = 2.2;

%Discretized Laplace (Troughton Goodsill, Ehler Brooks 2004)
%Initialize Discrete Laplace CDF
proposalsARMA(1).laplaceCDFP = discreteLaplaceCDF(proposalsARMA(1).proposalPParam1, proposalsARMA(1).proposalPParam2);
proposalsARMA(1).laplacePDFP = discreteLaplacePDF(proposalsARMA(1).proposalPParam1, proposalsARMA(1).proposalPParam2);
proposalsARMA(1).proposalP = @(x) sampleDiscreteLaplace(x, proposalsARMA(1).laplaceCDFP);
proposalsARMA(1).evaluateProposalP = @(x) evaluateDiscreteLaplacePDF(x(1),x(2),proposalsARMA(1).laplacePDFP);


%Proposals MA-Order
proposalsARMA(1).proposalQParam1 = settings.qMax;
proposalsARMA(1).proposalQParam2 = 2.2;
proposalsARMA(1).proposalQParam3 = 0/0;
proposalsARMA(1).proposalQParam4 = 0/0;
%Uniform Proposal: 
% proposalsARMA(1).proposalQ =  @(x) unidrnd(proposalsARMA(1).proposalQParam1 + 1) - 1;

%Discretized Laplace (Troughton Goodsill, Ehler Brooks 2004)
proposalsARMA(1).laplaceCDFQ = discreteLaplaceCDF(proposalsARMA(1).proposalQParam1, proposalsARMA(1).proposalQParam2);
proposalsARMA(1).laplacePDFQ = discreteLaplacePDF(proposalsARMA(1).proposalQParam1, proposalsARMA(1).proposalQParam2);
proposalsARMA(1).proposalQ = @(x) sampleDiscreteLaplace(x, proposalsARMA(1).laplaceCDFQ);
proposalsARMA(1).evaluateProposalQ = @(x) evaluateDiscreteLaplacePDF(x(1),x(2),proposalsARMA(1).laplacePDFQ);


%Make sure process count is consistent
if settings.useSamePriorProposal ~= 1
    if settings.processCount ~= size(priorsARMA,2)
        disp(['settings.processCount does not coincide with number of priors. Resetting to ' num2str(size(priorsARMA,2)) ]);
        settings.processCount = size(priorsARMA,2);
    end;
end;


end