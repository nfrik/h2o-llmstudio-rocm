FROM rocm/dev-ubuntu-20.04:5.3-complete

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt install -y python3.10 \
    && apt install -y python3.10-distutils \
    && rm -rf /var/lib/apt/lists/*

# Pick an unusual UID for the llmstudio user.
# In particular, don't pick 1000, which is the default ubuntu user number.
# Force ourselves to test with UID mismatches in the common case.
#RUN adduser --uid 1999 llmstudio
#USER root
#RUN adduser llmstudio sudo
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
#RUN mkdir -p /workspace && chown llmstudio:llmstudio /workspace
#USER llmstudio
#USER root

# Python virtualenv is installed in /home/llmstudio/.local
# Application code and data lives in /workspace
#
# Make all of the files in the llmstudio directory writable so that the
# application can install other (non-persisted) new packages and other things
# if it wants to.  This is really not advisable, though, since it's lost when
# the container exits.

WORKDIR /workspace
#RUN chown llmstudio:llmstudio -R /workspace

RUN mkdir /home/llmstudio

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 && \
    chmod -R a+w /home/llmstudio
№COPY . .
COPY Makefile .
COPY Pipfile .
#COPY Pipfile.lock .
#COPY requirements.txt .
#RUN pip install -r requirements.txt

#RUN make setup && chmod -R a+w /home/llmstudio

COPY . .

#RUN sudo chmod -R a+w /home/llmstudio
#RUN sudo chown llmstudio:llmstudio -R /home/llmstudio/h2o

#Install bitsandbytes rocm for MI100 GPU (gfx908)
WORKDIR /workspace/bitsandbytes-rocm
RUN make hip
RUN CUDA_VERSION=gfx908 python3 setup.py install
WORKDIR /workspace

ENV HOME=/home/llmstudio
ENV H2O_WAVE_MAX_REQUEST_SIZE=25MB
ENV H2O_WAVE_NO_LOG=true
ENV H2O_WAVE_PRIVATE_DIR="/download/@/workspace/output/download"
EXPOSE 10101
ENTRYPOINT [ "python3.10", "-m", "pipenv", "run", "wave", "run", "app" ]
