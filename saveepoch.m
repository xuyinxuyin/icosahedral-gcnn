expDir = fullfile('data', 'modelnet40','net-deployed.mat');
inDir=fullfile('data', 'modelnet40','net-epoch-5');
net=load(inDir);
net=net.net;
cnn_imagenet_deploy(net);
save(expDir, '-struct', 'net') ;
