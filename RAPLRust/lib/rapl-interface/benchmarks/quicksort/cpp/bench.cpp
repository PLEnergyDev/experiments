#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;
extern "C" {
    void start_rapl();
    void stop_rapl();
}

#include <iterator>
#include <algorithm>
#include <functional>
#include <string>
#include <vector>

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Code from rosetta start

// helper function for median of three
template<typename T>
 T median(T t1, T t2, T t3)
{
  if (t1 < t2)
  {
    if (t2 < t3)
      return t2;
    else if (t1 < t3)
      return t3;
    else
      return t1;
  }
  else
  {
    if (t1 < t3)
      return t1;
    else if (t2 < t3)
      return t3;
    else
      return t2;
  }
}

// helper object to get <= from <
template<typename Order> struct non_strict_op:
  public std::binary_function<typename Order::second_argument_type,
                              typename Order::first_argument_type,
                              bool>
{
  non_strict_op(Order o): order(o) {}
  bool operator()(typename Order::second_argument_type arg1,
                  typename Order::first_argument_type arg2) const
  {
    return !order(arg2, arg1);
  }
private:
  Order order;
};

template<typename Order> non_strict_op<Order> non_strict(Order o)
{
  return non_strict_op<Order>(o);
}

template<typename RandomAccessIterator,
         typename Order>
 void quicksort(RandomAccessIterator first, RandomAccessIterator last, Order order)
{
  if (first != last && first+1 != last)
  {
    typedef typename std::iterator_traits<RandomAccessIterator>::value_type value_type;
    RandomAccessIterator mid = first + (last - first)/2;
    value_type pivot = median(*first, *mid, *(last-1));
    RandomAccessIterator split1 = std::partition(first, last, std::bind2nd(order, pivot));
    RandomAccessIterator split2 = std::partition(split1, last, std::bind2nd(non_strict(order), pivot));
    quicksort(first, split1, order);
    quicksort(split2, last, order);
  }
}
// test method
template<typename RandomAccessIterator>
 void quicksort(RandomAccessIterator first, RandomAccessIterator last)
{
  quicksort(first, last, std::less<typename std::iterator_traits<RandomAccessIterator>::value_type>());
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Code from rosetta stop


// read a vector from a string, inspired by secound answer of https://stackoverflow.com/questions/14265581/parse-split-a-string-in-c-using-string-delimiter-standard-c
vector<int> IntVectorFromString(std::string str){
  vector<int> result;
  std::stringstream ss (str);
  std::string item;

  while (getline(ss, item, ',')) {
    result.push_back(std::atoi(item.c_str()));
  }

  return result;
}

// function for reading file, inspired by https://www.w3schools.com/cpp/cpp_files.asp
std::string readFile(std::string path){
  ifstream file(path);
  std::string str;

  while (getline(file, str)) {
    // do nothing
  }
  file.close();

  return str;
}

int main(int argc, char *argv[]) {

    std::string inputRaw = readFile(argv[2]);

    // removing brackets
    inputRaw.erase(remove(inputRaw.begin(), inputRaw.end(), ']'), inputRaw.end());
    inputRaw.erase(remove(inputRaw.begin(), inputRaw.end(), '['), inputRaw.end());


    // getting numbers from input
    vector<int> sortParam = IntVectorFromString(inputRaw);


    int count = std::atoi(argv[1]);

    for (int i = 0; i < count; i++) {
        // copying sortParam to avoid changing it
        vector<int> sortParamCopy = vector<int>(sortParam);

        start_rapl();

        quicksort(sortParamCopy.begin(), sortParamCopy.end());

        stop_rapl();

        // stopping compiler optimizations
        if (sortParamCopy.size() < 42){
            std::cout << "Result: " << sortParamCopy[0] << std::endl;
        }
    }

    return 0;
}