#---------------------------------------------------------------------
# Makefile for VanitySearch
#
# Author : Jean-Luc PONS

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
        GPU/GPUEngine.o Bech32.o Wildcard.o wildcard_test.o)

else

OBJET = $(addprefix $(OBJDIR)/, \
        Base58.o IntGroup.o main.o Random.o Timer.o Int.o \
        IntMod.o Point.o SECP256K1.o Vanity.o GPU/GPUGenerate.o \
        hash/ripemd160.o hash/sha256.o hash/sha512.o \
        hash/ripemd160_sse.o hash/sha256_sse.o Bech32.o Wildcard.o wildcard_test.o)

endif

# 添加 GTest 源文件路径
GTEST_DIR = third_party/googletest/googletest
GTEST_HEADERS = $(GTEST_DIR)/include/gtest/*.h \
                $(GTEST_DIR)/include/gtest/internal/*.h
GTEST_SRCS = $(GTEST_DIR)/src/*.cc $(GTEST_DIR)/src/*.h

# 添加 GTest 编译选项
GTEST_CPPFLAGS = -isystem $(GTEST_DIR)/include
GTEST_CXXFLAGS = -g -Wall -Wextra -pthread

# 添加 GTest 目标
GTEST_OBJS = $(OBJDIR)/gtest-all.o
CXX        = g++-14
CUDA       = /usr/local/cuda-8.0
CXXCUDA    = /usr/bin/g++-4.8
NVCC       = $(CUDA)/bin/nvcc
GTEST_INCLUDE = $(GTEST_DIR)/include

# nvcc requires joint notation w/o dot, i.e. "5.2" -> "52"
ccap       = $(shell echo $(CCAP) | tr -d '.')

ifdef gpu
ifdef debug
CXXFLAGS   = -DWITHGPU -m64  -mssse3 -Wno-write-strings -g -I. -I$(CUDA)/include -I$(GTEST_INCLUDE) 
else
CXXFLAGS   =  -DWITHGPU -m64 -mssse3 -Wno-write-strings -O2 -I. -I$(CUDA)/include -I$(GTEST_INCLUDE)
endif
LFLAGS     = -lpthread -L$(CUDA)/lib64 -lcudart -lgtest -lgtest_main
else
ifdef debug
CXXFLAGS   = -m64 -mssse3 -Wno-write-strings -g -I. -I$(CUDA)/include -I$(GTEST_INCLUDE)
else
CXXFLAGS   =  -m64 -mssse3 -Wno-write-strings -O2 -I. -I$(CUDA)/include -I$(GTEST_INCLUDE)
endif
LFLAGS     = -lpthread
endif


#--------------------------------------------------------------------

ifdef gpu
ifdef debug
$(OBJDIR)/GPU/GPUEngine.o: GPU/GPUEngine.cu
	$(NVCC) -G -maxrregcount=0 --ptxas-options=-v --compile --compiler-options -fPIC -ccbin $(CXXCUDA) -m64 -g -I$(CUDA)/include -gencode=arch=compute_$(ccap),code=sm_$(ccap) -o $(OBJDIR)/GPU/GPUEngine.o -c GPU/GPUEngine.cu
else
$(OBJDIR)/GPU/GPUEngine.o: GPU/GPUEngine.cu
	$(NVCC) -maxrregcount=0 --ptxas-options=-v --compile --compiler-options -fPIC -ccbin $(CXXCUDA) -m64 -O2 -I$(CUDA)/include -gencode=arch=compute_$(ccap),code=sm_$(ccap) -o $(OBJDIR)/GPU/GPUEngine.o -c GPU/GPUEngine.cu
endif
endif

$(OBJDIR)/%.o : %.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

all: VanitySearch

VanitySearch: $(OBJET) $(OBJDIR)/gtest-all.o
	@echo Making VanitySearch...
	$(CXX) $(OBJET) $(GTEST_OBJS) $(LFLAGS) -o VanitySearch

$(OBJDIR)/gtest-all.o: $(GTEST_SRCS)
	$(CXX) $(GTEST_CPPFLAGS) $(CXXFLAGS) -I$(GTEST_DIR) -c \
	$(GTEST_DIR)/src/gtest-all.cc -o $@

$(OBJET): | $(OBJDIR) $(OBJDIR)/GPU $(OBJDIR)/hash

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/GPU: $(OBJDIR)
	cd $(OBJDIR) &&	mkdir -p GPU

$(OBJDIR)/hash: $(OBJDIR)
	cd $(OBJDIR) &&	mkdir -p hash

clean:
	@echo Cleaning...
	@rm -f obj/*.o
	@rm -f obj/GPU/*.o
	@rm -f obj/hash/*.o

