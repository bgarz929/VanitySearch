#---------------------------------------------------------------------
# Makefile for VanitySearch
#
# Author : Jean-Luc PONS
# Fixed for modern CUDA & compiler

SRC = Base58.cpp IntGroup.cpp main.cpp Random.cpp \
      Timer.cpp Int.cpp IntMod.cpp Point.cpp SECP256K1.cpp \
      Vanity.cpp GPU/GPUGenerate.cpp hash/ripemd160.cpp \
      hash/sha256.cpp hash/sha512.cpp hash/ripemd160_sse.cpp \
      hash/sha256_sse.cpp Bech32.cpp Wildcard.cpp

OBJDIR = obj

ifdef gpu
OBJET = $(addprefix $(OBJDIR)/, \
        Base58.o IntGroup.o main.o Random.o Timer.o Int.o \
        IntMod.o Point.o SECP256K1.o Vanity.o GPU/GPUGenerate.o \
        hash/ripemd160.o hash/sha256.o hash/sha512.o \
        hash/ripemd160_sse.o hash/sha256_sse.o \
        GPU/GPUEngine.o Bech32.o Wildcard.o)
else
OBJET = $(addprefix $(OBJDIR)/, \
        Base58.o IntGroup.o main.o Random.o Timer.o Int.o \
        IntMod.o Point.o SECP256K1.o Vanity.o GPU/GPUGenerate.o \
        hash/ripemd160.o hash/sha256.o hash/sha512.o \
        hash/ripemd160_sse.o hash/sha256_sse.o Bech32.o Wildcard.o)
endif

#---------------------------------------------------------------------
# Toolchain (AUTO, NO HARDCODE)

CXX     ?= g++
NVCC    ?= nvcc
CUDA    ?= /usr/local/cuda

# GPU architecture (DEFAULT = Turing / RTX 20xx)
CUDA_ARCH ?= 75

#---------------------------------------------------------------------

ifdef gpu
CXXFLAGS = -DWITHGPU -m64 -mssse3 -Wno-write-strings -O2 -I. -I$(CUDA)/include
LFLAGS   = -lpthread -L$(CUDA)/lib64 -lcudart
else
CXXFLAGS = -m64 -mssse3 -Wno-write-strings -O2 -I. -I$(CUDA)/include
LFLAGS   = -lpthread
endif

#---------------------------------------------------------------------
# GPU build rule

ifdef gpu
$(OBJDIR)/GPU/GPUEngine.o: GPU/GPUEngine.cu
	$(NVCC) -O2 --compiler-options -fPIC \
	-I$(CUDA)/include \
	-gencode=arch=compute_$(CUDA_ARCH),code=sm_$(CUDA_ARCH) \
	-c GPU/GPUEngine.cu \
	-o $(OBJDIR)/GPU/GPUEngine.o
endif

#---------------------------------------------------------------------

$(OBJDIR)/%.o : %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

all: VanitySearch

VanitySearch: $(OBJET)
	@echo Making VanitySearch...
	$(CXX) $(OBJET) $(LFLAGS) -o VanitySearch

$(OBJET): | $(OBJDIR) $(OBJDIR)/GPU $(OBJDIR)/hash

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/GPU: $(OBJDIR)
	mkdir -p $(OBJDIR)/GPU

$(OBJDIR)/hash: $(OBJDIR)
	mkdir -p $(OBJDIR)/hash

clean:
	@echo Cleaning...
	@rm -f obj/*.o
	@rm -f obj/GPU/*.o
	@rm -f obj/hash/*.o
