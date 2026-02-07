#---------------------------------------------------------------------
# Makefile for VanitySearch (FINAL FIX)

CXX     ?= g++
NVCC    ?= nvcc
CUDA    ?= /usr/local/cuda
CUDA_ARCH ?= 75

OBJDIR = obj

SRC_CPP = Base58.cpp IntGroup.cpp main.cpp Random.cpp \
          Timer.cpp Int.cpp IntMod.cpp Point.cpp SECP256K1.cpp \
          Vanity.cpp hash/ripemd160.cpp hash/sha256.cpp hash/sha512.cpp \
          hash/ripemd160_sse.cpp hash/sha256_sse.cpp Bech32.cpp Wildcard.cpp \
          GPU/GPUGenerate.cpp

OBJ_CPP = $(addprefix $(OBJDIR)/,$(SRC_CPP:.cpp=.o))

OBJ_GPU = $(OBJDIR)/GPU/GPUEngine.o

#-------------------------------------------------------------

CXXFLAGS = -m64 -mssse3 -Wno-write-strings -O2 -I. -I$(CUDA)/include
LFLAGS   = -lpthread

ifdef gpu
CXXFLAGS += -DWITHGPU
LFLAGS   += -L$(CUDA)/lib64 -lcudart
OBJ = $(OBJ_CPP) $(OBJ_GPU)
else
OBJ = $(OBJ_CPP)
endif

#-------------------------------------------------------------

all: VanitySearch

VanitySearch: $(OBJ)
	@echo "==> Linking VanitySearch"
	$(CXX) $(OBJ) $(LFLAGS) -o VanitySearch
	@echo "==> DONE: ./VanitySearch"

#-------------------------------------------------------------
# C++ objects

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

#-------------------------------------------------------------
# CUDA object

ifdef gpu
$(OBJDIR)/GPU/GPUEngine.o: GPU/GPUEngine.cu
	@mkdir -p $(OBJDIR)/GPU
	$(NVCC) -O2 --compiler-options -fPIC \
	-I$(CUDA)/include \
	-gencode=arch=compute_$(CUDA_ARCH),code=sm_$(CUDA_ARCH) \
	-c $< -o $@
endif

#-------------------------------------------------------------

clean:
	rm -rf obj VanitySearch
