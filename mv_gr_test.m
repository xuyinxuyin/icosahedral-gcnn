function mv_gr_test(nViews)
net=load('data/modelnet40_mv/net-deployed.mat');
imdb =load('data/modelnet40/imdb.mat');
% net=load('data/modelnet40_mv/net-epoch-11.mat');
% net=net.net;
% net = cnn_imagenet_deploy(net);
% imdb =load('data/modelnet40/imdb.mat');
test=find(imdb.images.set==3); 
test=test(1:nViews:end); 
opts.numFetchThreads=12;
opts.pad=32;
opts.border=32;
opts.aug='stretch';
opts.networkType='simplenn';
imdb.meta.nViews = nViews;

net=cnn_shape_test(net, imdb, getBatchFn(opts, net.meta),'nViews', nViews,'test',test);


end
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
end



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
end