%% klibaite et al mouse data for cajal tutorial
% some useful notes/code for following along with the tutorial for
% unsupevised behavioral embedding/analysis
% simplified mouse dataset 


%% mouse - 5x3 for males and females
load('/Users/ugne/Dropbox/tutorial-data/mouseDataOFT.mat','sampleMales','sampleFemales')
% movie corresponds to MOUSE 5, DAY 1
fileName = '/Users/ugne/Dropbox/tutorial-data/OFT-0060-00.mp4';
vr = VideoReader(fileName);

% check movie for specific frames
idx = 2900:3500;
V = read(vr,[idx(1) idx(end)]);


% one skeleton 
load('mouseSkeletonSimple_400.mat')
skeleton.joints_idx = edges;
skeleton.color = ones(17,3);


% second skeleton - added colors for fun
% change these to suit your needs - which keypoints are most informative?
%skeleton.joints_idx = [1 2; 2 9; 9 16; 16 17; 17 18; 1 3; 1 4; 5 7; 6 8; 12 14; 13 15];
%skeleton.mcolor = ones(11,3);
%skeleton.color = ones(11,3);

skel.joints_idx = [1 2; 2 9; 9 16; 16 17; 17 18; 1 3; 1 4; 5 7; 6 8; 12 14; 13 15];
skel.color = [0 .447 .741;
    0.85 0.32 .098;
    .929 0.694 .125;
    .466 .674 .188;
    .737 .502 .7412; %
    .635 .078 .184;
    .85 .325 .098;
     0 .447 .741;
    .494 .1840 .556;
    .466 .674 .188
    .301 .745 .933;];
skel.mcolor = ones(18,3);


% sample movie for first 700 frames
% IF YOU WANT TO USE ANIMATOR, DOWNLOAD HERE:
% https://github.com/diegoaldarondo/Animator
% make sure it is in your path!

jc = sampleMales{5,1};
jc2 = permute(jc,[3 2 1]);
markers = jc2(idx,:,:);

figure(1);
h = cell(2,1);
h{1} = VideoAnimator(V,'Position',[0 0 1 1]);
h{2} = Keypoint2DAnimator(markers, skeleton,'Axes',h{1}.Axes);
axis off; 
Animator.linkAll(h)
% which skeleton are you using? must match the number of joints


% calculate distances from body part positions

xIdx = [1 2 5 6 7 8 12 13 14 15 16];
yIdx = [1 2 5 6 7 8 12 13 14 15 16];
% here we track the nose/snout, limbs, and tail point
[X Y] = meshgrid(xIdx,yIdx);
X = X(:); Y = Y(:);
IDX = find(X~=Y);


maleDists = cell(5,3);
for m = 1:5
    m
    for j = 1:3
        p1 = sampleMales{m,j};
        p1Dist = zeros(121,size(p1,3));
        for i = 1:size(p1Dist,1)
            p1Dist(i,:) = returnDist(squeeze(p1(X(i),:,:)),squeeze(p1(Y(i),:,:)));
        end
        p1Dsmooth = zeros(size(p1Dist));
        for i = 1:size(p1Dist,1)
            p1Dsmooth(i,:) = medfilt1(smooth(p1Dist(i,:),5),5);
        end
        p1Dist = p1Dsmooth(IDX,:);
        maleDists{m,j} = p1Dist;
    end
end


% This is the procedure for performing PCA when there are too many samples
% to load into memory at once - you can just do simple PCA in one go for
% these smaller sample sets if you wish (same result as running pca(data)

batchSize = 20000;
num = 15;
firstBatch = true;
currentImage = 0;

for j = 1:num
    fprintf(1,'\t File #%5i out of %5i\n',j,num);
    p1Dist = maleDists{num};
    if firstBatch
        firstBatch = false;
        if size(p1Dist,2)<batchSize
            cBatchSize = size(p1Dist,2);
            X = p1Dist';
        else
            cBatchSize = batchSize;
            X = p1Dist(:,randperm(size(p1Dist,2),cBatchSize))';
        end
        
        currentImage = batchSize;
        muv = sum(X);
        C = cov(X).*batchSize + (muv'*muv)./cBatchSize;
    else
        
        if size(p1Dist,2)<batchSize
            cBatchSize = size(p1Dist,2);
            X = p1Dist';
        else
            cBatchSize = batchSize;
            X = p1Dist(:,randperm(size(p1Dist,2),cBatchSize))';
        end
        
        tempMu = sum(X);
        muv = muv+tempMu;
        C = C + cov(X).*cBatchSize + (tempMu'*tempMu)./cBatchSize;
        currentImage = currentImage + cBatchSize;
        fprintf(1,['Current Image = ' num2str(currentImage) '\n']);
    end
end
L = currentImage;
muv = muv./L;
C = C./L - muv'*muv;

[vecs,vals] = eig(C);
vals = flipud(diag(vals));
vecs = fliplr(vecs);


% A short detour into postural+dynamic representations
% before we start preparing our data for embedding and comparison, lets
% look at the PCA and wavelet decomposition in more detail
% given the original data (here our body part time-series which captures
% the (2Dprojection of the) configuration of body parts at each point in 
% time (frame)

% A few visualization to help explore this data:

idtest = 1001:2000;
postureDataSample = sampleMales{5,1}(:,:,idtest);
psr = permute(postureDataSample,[3 2 1]);

for jointid = 1:18
    plot(psr(:,2,jointid)); hold on;
end
% joints here are in real space, let's look at animal-centric joints to
% make more sense of the behavior
% the functions findP1Nose.mat and findP1Center.mat can help you align the
% tracked markers to either the nose or center 

aligned = findP1Nose(postureDataSample);
imagec(aligned);

% before wavelet decomposition, specify the framerate of recording, and the
% minimum and maximum frequencies over which to find power spectra
minF = .25; maxF = 20;
parameters = setRunParameters([]);
parameters.samplingFreq = 80;
parameters.minF = minF;
parameters.maxF = maxF;
numModes = 36; % number of x and y streams
[data,~] = findWavelets(aligned',numModes,parameters);

imagesc(data');
imagesc(data(:,1:450)'); %x-only
imagesc(data(:,451:900)'); %y-only

% which body points have interesting features in the wavelet space here?
% Can you figure out what behavior is happening based on the power?




%% 


% Use vecs/vals from a larger embedding - using the same features is
% important if you want to reembed into the same map later!!
% these are the results from performing the online PCA from 100s of movies

load('vecsVals_subSelect.mat')



% construct a sample dataset on which to perform embeddings
% here I specify how many samples to take from each movie - each of these
% samplings takes a range of sample points by performing a tsne embedding
% on that movie only, and then grabbing samples from across the entire map
% this ensures we find rare behaviors and use them in our embedding, even
% if they only occur in a single movie, or if they are very rare in general

dataAll = [];

numProjections = 10;
numModes = 10; pcaModes = numModes;
minF = .25; maxF = 20;

parameters = setRunParameters([]);
parameters.trainingSetSize = 2000;
parameters.pcaModes = pcaModes;
parameters.samplingFreq = 80;
parameters.minF = minF;
parameters.maxF = maxF;
numPerDataSet = parameters.trainingSetSize;
numPoints = 5000;

for t = 1:15
    p1Dist = maleDists{t};
    p2Dist = bsxfun(@minus,p1Dist,muv');
projections = p2Dist'*vecs(:,1:numProjections);

[data,~] = findWavelets(projections,numModes,parameters);
amps = sum(data,2);

N = length(projections(:,1));
numModes = parameters.pcaModes;
skipLength = floor(N / numPoints);
if skipLength == 0
    skipLength = 1;
    numPoints = N;
end

firstFrame = mod(N,numPoints) + 1;
signalIdx = firstFrame:skipLength:(firstFrame + (numPoints-1)*skipLength);
%signalData = bsxfun(@rdivide,data(signalIdx,:),amps(signalIdx));
signalAmps = amps(signalIdx);
nnData = log(data(signalIdx,:));
nnData(nnData<-3) = -3;

yData = tsne(nnData);
[signalData,signalAmps] = findTemplatesFromData(...
                    nnData,yData,signalAmps,numPerDataSet,parameters);

dataAll = [dataAll; signalData];
end

tic
ydata = tsne(dataAll);
toc
tic
C100 = kmeans(dataAll,100,'Replicates',10);
toc

% ydata is your tsne embedding! 
% check how these embeddings compare! How do the k-means clusters overlay
% on the 2d tsne embedding. 
% go back and look at some wavelet or joint samples from a region of the
% map (or a single cluster) - do these share some properties?

scatter(ydata(:,1),ydata(:,2),'.')
scatter(ydata(:,1),ydata(:,2),[],C100,'.')

% you can save your map, from here on out we will use a previously made map
% and reembed a movie - this is because cataloguing all the clusters and
% assigning manual labels takes more time than we have right now. Also, you
% might take more movies and want to know how to re-embed into a map that
% already exists.
save('myTrainingSet.mat','dataAll','ydata','C100');

%%
% this is the training data (subsampled as you just did, but from 100s of
% movies) and tsne embedding and cluster labels I previously created
load('trainingSet_new10.mat', 'C100','ydata','dataAll')


addpath('utilities')
        
trainingSetData = dataAll; %trainingSetData(1:2:end,:);
trainingEmbedding = ydata; %ydata(1:2:end,:);
cdata1 = C100; % cdata1(1:2:end);

% this is the trial we have a movie for so lets embed that in order to
% explore our labels later
m = 5; d = 1;
p1Dist = maleDists{m,d};


% in order to embed into an already-existing map we must use the same
% parameters, method of projection, etc.
numProjections = 10; numModes = 10; pcaModes = 10;
parameters = [];
parameters = setRunParameters([]);
parameters.pcaModes = 10;
parameters.samplingFreq = 80;
parameters.minF = .25;
parameters.maxF = 20;
parameters.numModes = numModes;


% generate the projections 
p2Dist = bsxfun(@minus,p1Dist,muv');
projections = p2Dist'*vecs(:,1:numProjections);

fprintf(1,'Finding Wavelets\n');
numModes = parameters.pcaModes;

% find wavelet spectra
[data,f] = findWavelets(projections,numModes,parameters);
data = log(data); data(data<-3) = -3;
% this clipping comes from the original embedding - this is why we have to
% know exactly the procedure we used to reembed data. I performed clipping
% because it makes for a cleaner map - one of the many decisions we make on
% how to perform our dimensionality reduction



% ~17min for the whole movie, try a shorter clip instead. Can you explore
% the data in other ways in order to choose this clip (i.e. use centroid 
% tracking to find times of high or low movement and then embed a specific 
% time of interest)? do data(indexOfInterest,:) for smaller clips -
% remember to look at movies with the corresponding indices or your labels
% will seem very wrong!
tic
fprintf(1,'Finding Embeddings\n');
[zValues,zCosts,zGuesses,inConvHull,meanMax,exitFlags] = ...
    findTDistributedProjections_fmin(data,trainingSetData,...
    trainingEmbedding,[],parameters);

z = zValues; z(~inConvHull,:) = zGuesses(~inConvHull,:);
toc


tic
KK = 101;
[cGuesses] = reembedHDK(data,parameters,trainingSetData,cdata1,KK);
toc
% ~3.5min for whole movie 

% assign behavior labels from original embedding
% these are 8 coarse labels I ascribed to the movies in order to make
% statements about behavioral evolution and differences between groups
load('info_8con_8b.mat', 'sortid8','colors8')
cLabels = sortid8(cGuesses(:,1));

% 8 CLUSTER NAMES: idle, groom, slow explore, fast explore, rear, climb, turning, locomotion
% notice these are arranged generally from fast->slow 
% here are the colors I used for each of these 
cbarbeh = [26 26 255;
    102 205 255;
    225 179 217; %204 204 255;
    172 0 230; %152 78 163;
    102 255 153;
    0 204 0;
    255 204 0;
    228 26 28]./256;

% plot ethogram - you can play with this (try using imagesc on a matrix instead)
strand = cLabels(1:90000);
f = figure(10);
for i = 1:8
n = length(strand);
isl = find(strand==i); ww = zeros(size(strand)); ww(isl)=1;
cc = bwconncomp(ww);
plot([0 n],[i i],'Color','k','LineWidth',.5); hold on;
for j = 1:length(cc.PixelIdxList)
    y = [i i]; x = [cc.PixelIdxList{j}(1) cc.PixelIdxList{j}(end)];
    plot(x,y,'Color',cbarbeh(i,:),'LineWidth',10);
end
end
axis off
f.Position = [19 144 1774 105];
saveas(gcf,'ethogram90000.tif');



strand = cLabels(1:9000);
f2 = figure(11);
for i = 1:8
n = length(strand);
isl = find(strand==i); ww = zeros(size(strand)); ww(isl)=1;
cc = bwconncomp(ww);
plot([0 n],[i i],'Color','k','LineWidth',.5); hold on;
for j = 1:length(cc.PixelIdxList)
    y = [i i]; x = [cc.PixelIdxList{j}(1) cc.PixelIdxList{j}(end)];
    plot(x,y,'Color',cbarbeh(i,:),'LineWidth',10);
end
end
axis off
f2.Position = [19 144 1774 105];
saveas(gcf,'ethogram9000.tif');


strand = cLabels(1:900);
f3 = figure(12);
for i = 1:8
n = length(strand);
isl = find(strand==i); ww = zeros(size(strand)); ww(isl)=1;
cc = bwconncomp(ww);
plot([0 n],[i i],'Color','k','LineWidth',.5); hold on;
for j = 1:length(cc.PixelIdxList)
    y = [i i]; x = [cc.PixelIdxList{j}(1) cc.PixelIdxList{j}(end)];
    plot(x,y,'Color',cbarbeh(i,:),'LineWidth',10);
end
end
axis off
f3.Position = [19 144 1774 105];
saveas(gcf,'ethogram900.tif');

strand = cLabels(idx);
f3 = figure(12);
for i = 1:8
n = length(strand);
isl = find(strand==i); ww = zeros(size(strand)); ww(isl)=1;
cc = bwconncomp(ww);
plot([0 n],[i i],'Color','k','LineWidth',.5); hold on;
for j = 1:length(cc.PixelIdxList)
    y = [i i]; x = [cc.PixelIdxList{j}(1) cc.PixelIdxList{j}(end)];
    plot(x,y,'Color',cbarbeh(i,:),'LineWidth',10);
end
end
axis off
f3.Position = [19 144 1774 105];
saveas(gcf,'ethogram900.tif');


% now look at a snippet of behavior and compare to the same indices for the
% movie!! Does this labeling capture what the animal is doing?


% can you explore differences between what the fine-grained clusters
% represent and see the logic of the grouping I came to for course labels?


% the sample data includes some female movies as well - can you compare the
% behavior between these two groups using reembedding? How do these groups
% differ?



% if this seems to all make sense: can I interest you in some 3D rodent
% data? 
