FROM nvidia/cuda:10.1-base

# install git for accessing repositories 
# and make /opt accessible for all users
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    chmod 777 /opt

SHELL ["/bin/bash", "-c"]

# install miniconda into /opt/conda and delete downloaded file
ENV CONDAROOT "/opt/conda"
WORKDIR /root/
ADD https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh /root/
RUN mkdir ~/.conda && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $CONDAROOT && \
    rm -rf Miniconda3-latest-Linux-x86_64.sh && \
    source $CONDAROOT/etc/profile.d/conda.sh
#ln -s $CONDAROOT/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# add conda to the path
ENV PATH $CONDAROOT/bin:$PATH

# Install pytorch and fastai through conda
RUN conda update -n base -c defaults conda && \
    conda create -n torch -y python=3.7 && \
    conda install -n torch pytorch torchvision cudatoolkit=10.1 -c pytorch && \
    conda install -n torch -c pytorch -c fastai fastai && \
    conda install -n torch -c conda-forge imageio matplotlib seaborn pandas jupyter jupyterlab scikit-image scikit-learn tqdm jupyter_contrib_nbextensions nodejs tensorboard grpcio

# This would install pillow-simd with optimized libjpeg
# but currently this leads to a version clash of pillow 6.1 and pillow-simd 6.0
# RUN conda uninstall -n torch -y --force pillow pil jpeg libtiff libjpeg-turbo && \
#     apt-get install -y gcc && \
#     source activate torch &&\
#     pip   uninstall -y         pillow pil jpeg libtiff libjpeg-turbo && \
#     conda install -n torch -yc conda-forge libjpeg-turbo && \
#     CFLAGS="${CFLAGS} -mavx2" pip install --upgrade --no-cache-dir --force-reinstall --no-binary :all: --compile pillow-simd

# activate the torch environment to install further packages with pip which are not available or outdated on conda
ENV PATH $CONDAROOT/envs/torch/bin:$PATH
RUN echo "source activate torch" >> ~/.bashrc && \
    source activate torch &&\
    pip install opencv-python albumentations pretrainedmodels efficientnet-pytorch torchsummary future absl-py jupyter-tensorboard hiddenlayer && \
    pip install --no-dependencies git+https://github.com/qubvel/segmentation_models.pytorch
# pip install pytest-xdist pytest-sugar pytest-repeat pytest-picked pytest-forked pytest-flakefinder pytest-cov nbsmoke

# configure jupyter-lab to run in the docker image as root with bash as terminal and no password
# notebook directory is /opt/notebooks ==> this should be your mount point
RUN jupyter-lab --generate-config
RUN sed -i '/c.NotebookApp.notebook_dir/c\c.NotebookApp.notebook_dir = "'"/opt/notebooks"'"' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.open_browser/c\c.NotebookApp.open_browser = False' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.quit_button/c\c.NotebookApp.quit_button = True' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.token/c\c.NotebookApp.token = "'""'"' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.ip/c\c.NotebookApp.ip = "'"0.0.0.0"'"' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.terminado_settings/c\c.NotebookApp.terminado_settings = {"'"shell_command"'":["'"bash"'"]}' ~/.jupyter/jupyter_notebook_config.py && \
    sed -i '/c.NotebookApp.allow_root/c\c.NotebookApp.allow_root = True' ~/.jupyter/jupyter_notebook_config.py && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
    jupyter labextension install jupyterlab_tensorboard && \
    mkdir /opt/notebooks
WORKDIR /opt/notebooks

# Set the random seed and copy the utility scripts to the image
ENV RANDOM_SEED 2019
COPY torchtest.py seed.py /opt/scripts/

# this script runs seed.py whenever an ipython kernel/console is started
COPY ipython_config.py ~/.ipython/profile_default/

RUN mkdir /opt/cache && \
    pip freeze > ~/requirements.txt && \
    conda list -n torch --export --json > ~/requirements.json
ENV TORCH_HOME ~/cache/torch
ENV FASTAI_HOME ~/cache/fastai
ENV HOME /root/
RUN chmod -R a+rwX /root && \
    chmod -R a+rwX /opt

# Make port 8888 available to the world outside this container
EXPOSE 8888

# Run the torchtest script when the container launches (and no other command is given)
CMD ["ipython", "/opt/scripts/torchtest.py"]
