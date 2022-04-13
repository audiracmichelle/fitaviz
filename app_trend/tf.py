#%%
import numpy as np
import pandas as pd
import torch
from torch import nn, optim
import torch.nn.functional as F
import datetime as dt

def adjust_trend_and_seasonality(
    y, lam, epochs=3000, init_lr=1.0, huber_k=0.1, tv_order=0
):
    def huber(x, k = 1.0):
        x = x.abs()
        return torch.where(x <= k, 0.5 * x.pow(2), k * (x - 0.5 * k))
    def tv_penalty(x, order=0, huber_k=1.0):
        # # this pads extra values in x so that
        # ndims = len(x.shape)
        # # xt - x(t-1) has the same size as x with zeros
        # new_dims = 4 - ndims
        # for _ in range(new_dims):
        #     x = x.unsqueeze(0)
        # x = F.pad(x, [0, 0, order, order], mode='replicate')
        # for _ in range(new_dims):
        #     x = x.squeeze(0)
        dx = x[1:] - x[:-1]
        for o in range(order):
            dx = dx[1:] - dx[:-1]
        return huber(dx, huber_k).sum()
    class TrendFilter(nn.Module):
        def __init__(self, T, K, S=7):
            super().__init__()
            self.T = T
            self.S = S
            self.K = K
            self.s = nn.Parameter(torch.zeros((self.S - 1, self.K)))
            self.x = nn.Parameter(torch.zeros((self.T, self.K)))
        def seasonal_effect(self, pad=True):
            shat = torch.cat([torch.zeros(1, self.K), self.s])
            if pad:
                shat = shat[np.arange(self.T) % self.S]
            return shat
        def forward(self):
            shat = self.seasonal_effect()
            yhat = shat + self.x
            return yhat
    # create mask and replace missing with zeros
    T = len(y)
    mask = ~np.isnan(y)
    y_ = np.array(y).copy()
    y_[np.isnan(y_)] = 0.0
    # make tensors
    y_ = torch.FloatTensor(y_).unsqueeze(1)
    mask = torch.FloatTensor(mask).unsqueeze(1)
    # make model
    mod = TrendFilter(T, 1)
    # ADAM optimizer
    opt = optim.Adam(mod.parameters(), lr=init_lr)
    sched = optim.lr_scheduler.ReduceLROnPlateau(
        opt, patience=10, factor=0.9, min_lr=1e-4
    )
    # optimize
    for e in range(epochs):
        opt.zero_grad()
        yhat = mod()
        err = mask * (y_ - yhat)
        ll =  err.pow(2).sum()
        reg = tv_penalty(
            mod.x, huber_k=huber_k, order=tv_order
        )
        loss = ll + lam * reg
        loss.backward()
        opt.step()
        sched.step(loss)
    output = dict(
        yhat=mod().detach().numpy().squeeze(),
        trend=mod.x.detach().numpy().squeeze(),
        seasonal=mod.seasonal_effect(pad=True).detach().numpy().squeeze()
    )
    return output
