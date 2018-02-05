clear all; close all; clc
addpath(genpath('/Users/jacek/PROJECTS/COMMON'));

dataPath='../data/BRA_AL/BRA_AL_NSP1-128channels';
filename=fullfile(dataPath,'zHMmGZ_20171208-105112-001.ns3');

%%
data=openNSx(filename);
ts=data.Data;
ts=ts{2};




