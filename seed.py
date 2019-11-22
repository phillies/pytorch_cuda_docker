import os


def seed_all(seed):
    # python RNG
    import random
    random.seed(seed)

    # pytorch RNGs
    try:
        import torch
        torch.manual_seed(seed)
        torch.backends.cudnn.deterministic = True
        if torch.cuda.is_available(): torch.cuda.manual_seed_all(seed)
    except ImportError:
        print('Could not load torch.')

    # numpy RNG
    try:
        import numpy as np
        np.random.seed(seed)
    except ImportError:
        print('Could not load numpy.')

    print(f'seed set to {seed}')


if __name__ == '__main__':
    seed = int(os.environ.get('RANDOM_SEED', 42))
    seed_all(seed)