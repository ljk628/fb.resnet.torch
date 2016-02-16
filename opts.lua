--
--  Copyright (c) 2016, Facebook, Inc.
--  All rights reserved.
--
--  This source code is licensed under the BSD-style license found in the
--  LICENSE file in the root directory of this source tree. An additional grant
--  of patent rights can be found in the PATENTS file in the same directory.
--
local M = { }

function M.parse(arg)
   local cmd = torch.CmdLine()
   cmd:text()
   cmd:text('Torch-7 ResNet Training script')
   cmd:text()
   cmd:text('Options:')
    ------------ General options --------------------
   cmd:option('-cache', './log/', 'directory to save training result')
   cmd:option('-data',     '',        'Path to dataset')
   cmd:option('-dataset', 'imagenet', 'Options: imagenet | cifar10')
   cmd:option('-manualSeed',         2, 'Manually set RNG seed')
   cmd:option('-nGPU',               1, 'Number of GPUs to use by default')
   cmd:option('-backend',     'cudnn', 'Options: cudnn | cunn')
   cmd:option('-cudnn',     'fastest', 'Options: fastest | default | deterministic')
   ------------- Data options ------------------------
   cmd:option('-nThreads',        2, 'number of data loading threads')
   ------------- Training options --------------------
   cmd:option('-nEpochs',         0,    'Number of total epochs to run')
   cmd:option('-epochNumber',     1,     'Manual epoch number (useful on restarts)')
   cmd:option('-batchSize',       32,    'mini-batch size (1 = pure stochastic)')
   cmd:option('-testOnly',        false, 'Run on validation set only')
   cmd:option('-tenCrop',         false, 'Ten-crop testing')
   cmd:option('-verbose',         false, 'display results after each minibatch')
   cmd:option('-saveModel',       true,  'save model to file after each epoch' )
   ---------- Optimization options ----------------------
   cmd:option('-LR',              0.1,   'initial learning rate')
   cmd:option('-momentum',        0.9,   'momentum')
   cmd:option('-weightDecay',     1e-4,  'weight decay')
   ---------- Model options ----------------------------------
   cmd:option('-netType',      'resnet', 'Options: resnet')
   cmd:option('-depth',        34,       'ResNet depth: 18 | 34 | 50 | 101 | ...', 'number')
   cmd:option('-shortcutType', '',      'Options: A | B | C')
   cmd:option('-retrain',      'none', 'Path to model to retrain with')
   cmd:option('-optimState',   'none', 'Path to an optimState to reload from')
   ---------- Model options ----------------------------------
   cmd:option('-shareGradInput', false,  'Share gradInput tensors to reduce memory usage')
   cmd:option('-resetClassifier', false, 'Reset the fully connected layer for fine-tuning')
   cmd:option('-nClasses',       0,      'Number of classes in the dataset')
   cmd:text()

   local opt = cmd:parse(arg or {})

   if opt.dataset == 'imagenet' then
      -- Handle the most common case of missing -data flag
      local trainDir = paths.concat(opt.data, 'train')
      if not paths.dirp(opt.data) then
         cmd:error('error: missing ImageNet data directory')
      elseif not paths.dirp(trainDir) then
         cmd:error('error: ImageNet missing `train` directory: ' .. trainDir)
      end
      -- Default shortcutType=B and nEpochs=90
      opt.shortcutType = opt.shortcutType == '' and 'B' or opt.shortcutType
      opt.nEpochs = opt.nEpochs == 0 and 90 or opt.nEpochs
   elseif opt.dataset == 'cifar10' then
      -- Default shortcutType=A and nEpochs=164
      opt.shortcutType = opt.shortcutType == '' and 'A' or opt.shortcutType
      opt.nEpochs = opt.nEpochs == 0 and 164 or opt.nEpochs
   else
      cmd:error('unknown dataset: ' .. opt.dataset)
   end

   if opt.resetClassifier then
      if opt.nClasses == 0 then
         cmd:error('-nClasses required when resetClassifier is set')
      end
   end

   local modelName = opt.netType .. '-' .. opt.depth .. '-' .. opt.shortcutType
   opt.save = paths.concat(opt.cache, 
                           cmd:string(opt.dataset .. '/' .. modelName , opt,
                           {cache=true, data=true, dataset=true, netType=true, 
                            depth=true, shortcutType=true, retrain=true, 
                            verbose=true, saveModel=true,
                            optimState=true, epochNumber=true, nEpochs=true, batchSize=false}))
   -- opt.save = paths.concat(opt.save, '' .. os.date():gsub(' ',''))
  
   return opt
end

return M
