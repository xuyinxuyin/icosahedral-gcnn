function net = cnn_shape(dataName, varargin)
%CNN_SHAPE Train an MVCNN on a provided dataset 
%
%   dataName:: 
%     must be name of a folder under data/
%   `baseModel`:: 'imagenet-matconvnet-vgg-m'
%     learning starting point
%   `fromScratch`:: false
%     if false, only the last layer is initialized randomly
%     if true, all the weight layers are initialized randomly
%   `numFetchThreads`::
%     #threads for vl_imreadjpeg
%   `aug`:: 'none'
%     specifies the operations (fliping, perturbation, etc.) used 
%     to get sub-regions
%   `viewpoolPos` :: 'relu5'
%     location of the viewpool layer, only used when multiview is true
%   `includeVal`:: false
%     if true, validation set is also used for training 
%   `useUprightAssumption`:: true
%     if true, 12 views will be used to render meshes, 
%     otherwise 80 views based on a dodecahedron
% 
%   `train` 
%     training parameters: 
%       `learningRate`:: [0.001*ones(1, 10) 0.0001*ones(1, 10) 0.00001*ones(1,10)]
%         learning rate
%       `batchSize`: 128
%         set to a smaller number on limited memory
%       `momentum`:: 0.9
%         learning momentum
%       `gpus` :: []
%         a list of available gpus
% 
% Hang Su

opts.networkType = 'simplenn'; % only simplenn is supported currently 
opts.baseModel = 'imagenet-matconvnet-vgg-m';
opts.fromScratch = false; 
opts.dataRoot = 'data' ;
opts.imageExt = '.jpg';
opts.numFetchThreads = 0 ;
opts.multiview = true; 
opts.viewpoolPos = 'relu5';
%opts.useUprightAssumption = true;
opts.useUprightAssumption = false;
opts.aug = 'stretch';
opts.pad = 0; 
opts.border = 0; 
opts.numEpochs = [5 10 20]; 
opts.includeVal = false;
[opts, varargin] = vl_argparse(opts, varargin) ;

if strcmpi(opts.baseModel(end-3:end),'.mat'), 
  [~,modelNameStr] = fileparts(opts.baseModel); 
  opts.baseModel = load(opts.baseModel);
else
  modelNameStr = opts.baseModel; 
end

if opts.multiview, 
  opts.expDir = sprintf('%s-ft-%s-%s-%s', ...
    modelNameStr, ...
    dataName, ...
    opts.viewpoolPos, ...
    opts.networkType); 
else
  opts.expDir = sprintf('%s-ft-%s-%s', ...
    modelNameStr, ...
    dataName, ...
    opts.networkType); 
end
opts.expDir = fullfile(opts.dataRoot, opts.expDir);
[opts, varargin] = vl_argparse(opts,varargin) ;

opts.train.learningRate = [0.005*ones(1, 5) 0.001*ones(1, 5) 0.0001*ones(1,10) 0.00001*ones(1,10)];
opts.train.momentum = 0.9; 
opts.train.batchSize = 256; 
opts.train.maxIterPerEpoch = [Inf, Inf]; 
opts.train.balancingFunction = {[], []}; 
opts.train.gpus = []; 
opts.train = vl_argparse(opts.train, varargin) ;

if ~exist(opts.expDir, 'dir'), vl_xmkdir(opts.expDir) ; end

assert(strcmp(opts.networkType,'simplenn'), 'Only simplenn is supported currently'); 

% -------------------------------------------------------------------------
%                                                             Prepare data
% -------------------------------------------------------------------------
imdb = get_imdb(dataName); 
if ~opts.multiview, 
  nViews = 1;
else
  nShapes = length(unique(imdb.images.sid));
  nViews = length(imdb.images.id)/nShapes;
end
imdb.meta.nViews = nViews; 

opts.train.train = find(imdb.images.set==1);
opts.train.val = find(imdb.images.set==2); 
if opts.includeVal, 
  opts.train.train = [opts.train.train opts.train.val];
  opts.train.val = [];
end
opts.train.train = opts.train.train(1:nViews:end);
opts.train.val = opts.train.val(1:nViews:end); 

% -------------------------------------------------------------------------
%                                                            Prepare model
% -------------------------------------------------------------------------
net = cnn_shape_init6(imdb.meta.classes, ...
  'base', opts.baseModel, ...
  'restart', opts.fromScratch, ...
  'nViews', nViews, ...
  'viewpoolPos', opts.viewpoolPos, ...
  'networkType', opts.networkType);  


% -------------------------------------------------------------------------
%                                                                    Learn 
% -------------------------------------------------------------------------
switch opts.networkType
  case 'simplenn', trainFn = @cnn_shape_train ;
  case 'dagnn', trainFn = @cnn_train_dag ;
end
if nViews==1
trainable_layers = find(cellfun(@(l) isfield(l,'weights')&&~isempty(l.weights),net.layers)); 
fc_layers = find(cellfun(@(s) numel(s.name)>=2 && strcmp(s.name(1:2),'fc'),net.layers));
fc_layers = intersect(fc_layers, trainable_layers); 
lr = cellfun(@(l) l.learningRate, net.layers(trainable_layers),'UniformOutput',false); 
%layers_for_update = {trainable_layers(end), fc_layers, trainable_layers}; 
layers_for_update = {fc_layers, fc_layers, trainable_layers(end)}; 
else
trainable_layers = find(cellfun(@(l) isfield(l,'weights')&&~isempty(l.weights),net.layers)); 
gr_layers = find(cellfun(@(s) numel(s.name)>=2 && strcmp(s.name(1:2),'gr'),net.layers));
gr_layers = intersect(gr_layers, trainable_layers); 
lr = cellfun(@(l) l.learningRate, net.layers(trainable_layers),'UniformOutput',false); 
layers_for_update = {trainable_layers(end), gr_layers, trainable_layers}; 
end

for s=1:numel(opts.numEpochs), 
  if opts.numEpochs(s)<1, continue; end
  for i=1:numel(trainable_layers), 
    l = trainable_layers(i);
    if ismember(l,layers_for_update{s}), 
      net.layers{l}.learningRate = lr{i};
    else
      net.layers{l}.learningRate = lr{i}*0;
    end
  end

  net = trainFn(net, imdb, getBatchFn(opts, net.meta), ...
    'expDir', opts.expDir, ...
    net.meta.trainOpts, ...
    opts.train, ...
    'numEpochs', sum(opts.numEpochs(1:s)),...
    'nViews', nViews) ;        %modify
end

% -------------------------------------------------------------------------
%                                                                   Deploy
% -------------------------------------------------------------------------
net = cnn_imagenet_deploy(net) ;
modelPath = fullfile(opts.expDir, 'net-deployed.mat');
switch opts.networkType
  case 'simplenn'
    save(modelPath, '-struct', 'net') ;
  case 'dagnn'
    net_ = net.saveobj() ;
    save(modelPath, '-struct', 'net_') ;
    clear net_ ;
end

% -------------------------------------------------------------------------
function fn = getBatchFn(opts, meta)
% -------------------------------------------------------------------------
bopts.numThreads = opts.numFetchThreads ;
bopts.pad = opts.pad; 
bopts.border = opts.border ;
bopts.transformation = opts.aug ;
bopts.imageSize = meta.normalization.imageSize ;
bopts.averageImage = meta.normalization.averageImage ;
bopts.rgbVariance = meta.augmentation.rgbVariance ;
% bopts.transformation = meta.augmentation.transformation ;

switch lower(opts.networkType)
  case 'simplenn'
    fn = @(x,y) getSimpleNNBatch(bopts,x,y) ;
  case 'dagnn'
    error('dagnn version not yet implemented');
end

% -------------------------------------------------------------------------
function [im,labels] = getSimpleNNBatch(opts, imdb, batch)
% -------------------------------------------------------------------------
if nargout > 1, labels = imdb.images.class(batch); end
isVal = ~isempty(batch) && imdb.images.set(batch(1)) ~= 1 ;
nViews = imdb.meta.nViews; 

batch = bsxfun(@plus,repmat(batch(:)',[nViews 1]),(0:nViews-1)');
batch = batch(:)'; 

images = strcat([imdb.imageDir filesep], imdb.images.name(batch)) ;

if ~isVal, % training
  im = cnn_shape_get_batch(images, opts, ...
    'prefetch', nargout == 0, ...
    'nViews', nViews); 
else
  im = cnn_shape_get_batch(images, opts, ...
    'prefetch', nargout == 0, ...
    'nViews', nViews, ...
    'transformation', 'none'); 
end

nAugs = size(im,4)/numel(images); 
if nargout > 1, labels = repmat(labels(:)',[1 nAugs]); end

