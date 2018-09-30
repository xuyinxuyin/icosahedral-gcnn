net=load('data/modelnet40v1_mv/net-deployed.mat');
net.mode = 'test' ;
% prepare data
imdb =load('data/modelnet40v1/imdb.mat'); 

%opts.train.train = find(imdb.images.set==1);
opts.train.test = find(imdb.images.set==3); 
opts.dataDir = fullfile('data','image') ;
opts.expDir  = fullfile('exp', 'image') ;



for i = 1:length(opts.train.test)
    index = opts.train.test(i);
    label = imdb.images.label(index);
    % 读取测试的样本
    im_ =  imread(fullfile(imdb.imageDir.test,imdb.images.name{index}));
    im_ = single(im_);
    im_ = imresize(im_, net1.meta.normalization.imageSize(1:2)) ;
    im_ = bsxfun(@minus, im_, net1.meta.normalization.averageImage) ;
    % 测试
    net1.eval({'input',im_}) ;
    scores = net1.vars(net1.getVarIndex('prob')).value ;
    scores = squeeze(gather(scores)) ;

    [bestScore, best] = max(scores) ;
    truth(i) = label;
    pre(i) = best; 
end
accurcy = length(find(pre==truth))/length(truth);
disp(['accurcy = ',num2str(accurcy*100),'%']);