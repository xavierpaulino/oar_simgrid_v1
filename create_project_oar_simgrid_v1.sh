#!/bin/bash
set -e
BASE_DIR="$(pwd)/oar_simgrid_schedulers_v1"
rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR/platforms" "$BASE_DIR/src" "$BASE_DIR/tests"


cat > "$BASE_DIR/platforms/grid5000_like_64nodes.xml" <<'XML'
<?xml version='1.0'?>
<!DOCTYPE platform SYSTEM "https://simgrid.org/simgrid.dtd">
<platform version="4.1">
  <zone id="world" routing="Full">
XML

# Diversity-preserving 64-node Grid'5000-like platform.
# The architectures: x86_64, aarch64and ppc64le.
for i in $(seq 0 63); do
  if [ "$i" -lt 48 ]; then
    # x86_64: representative Intel Xeon and AMD EPYC clusters.
    case $((i % 4)) in
      0) site="grenoble"; cluster="dahu"; vendor="Intel"; cputype="Intel_Xeon_Gold_6130"; speed="2.1Gf"; cpufreq="2.1"; sockets="2"; cores="32"; threads="64"; mem_mb="196608"; idle="85"; active="180"; disktype="SATA/SSD"; disk_count="2"; eth_rate="10"; ib="NO"; ib_rate="0"; opa_rate="100"; gpu_count="0"; gpu_model="none"; gpu_mem="0" ;;
      1) site="lyon"; cluster="nova"; vendor="Intel"; cputype="Intel_Xeon_Gold_6240"; speed="2.6Gf"; cpufreq="2.6"; sockets="2"; cores="36"; threads="72"; mem_mb="196608"; idle="95"; active="210"; disktype="NVME/SSD"; disk_count="1"; eth_rate="25"; ib="EDR"; ib_rate="100"; opa_rate="0"; gpu_count="0"; gpu_model="none"; gpu_mem="0" ;;
      2) site="nancy"; cluster="gros"; vendor="AMD"; cputype="AMD_EPYC_7452"; speed="3.0Gf"; cpufreq="2.35"; sockets="2"; cores="64"; threads="128"; mem_mb="524288"; idle="110"; active="250"; disktype="NVME/SSD"; disk_count="2"; eth_rate="100"; ib="HDR"; ib_rate="200"; opa_rate="0"; gpu_count="0"; gpu_model="none"; gpu_mem="0" ;;
      3) site="rennes"; cluster="paravance"; vendor="AMD"; cputype="AMD_EPYC_7413"; speed="2.65Gf"; cpufreq="2.65"; sockets="2"; cores="48"; threads="96"; mem_mb="262144"; idle="100"; active="225"; disktype="SAS/HDD"; disk_count="1"; eth_rate="25"; ib="FDR"; ib_rate="56"; opa_rate="0"; gpu_count="1"; gpu_model="Tesla_V100_PCIE_32GB"; gpu_mem="32768" ;;
    esac
    arch="x86_64"
  elif [ "$i" -lt 56 ]; then
    # aarch64: ThunderX2, Grace and Carmel representatives.
    case $((i % 3)) in
      0) site="grenoble"; cluster="yeti"; vendor="Cavium"; cputype="ThunderX2_99xx"; speed="2.5Gf"; cpufreq="2.5"; sockets="2"; cores="32"; threads="128"; mem_mb="256000"; idle="80"; active="175"; disktype="NVME/SSD"; disk_count="1"; eth_rate="100"; ib="EDR"; ib_rate="100"; opa_rate="0"; gpu_count="0"; gpu_model="none"; gpu_mem="0" ;;
      1) site="luxembourg"; cluster="grace"; vendor="NVIDIA_ARM"; cputype="Grace_A02_CPU"; speed="3.2Gf"; cpufreq="3.2"; sockets="1"; cores="72"; threads="72"; mem_mb="491520"; idle="120"; active="270"; disktype="NVME/SSD"; disk_count="2"; eth_rate="100"; ib="HDR"; ib_rate="200"; opa_rate="0"; gpu_count="1"; gpu_model="Grace_Hopper"; gpu_mem="97887" ;;
      2) site="strasbourg"; cluster="troll"; vendor="NVIDIA_ARM"; cputype="Nvidia_Carmel"; speed="2.3Gf"; cpufreq="2.3"; sockets="1"; cores="8"; threads="8"; mem_mb="65536"; idle="45"; active="110"; disktype="SATA/SSD"; disk_count="1"; eth_rate="10"; ib="NO"; ib_rate="0"; opa_rate="0"; gpu_count="1"; gpu_model="Jetson_AGX"; gpu_mem="32768" ;;
    esac
    arch="aarch64"
  else
    # ppc64le: IBM POWER8NVL representative nodes.
    site="grenoble"; cluster="chifflet"; vendor="IBM"; cputype="POWER8NVL_1.0"; speed="3.0Gf"; cpufreq="3.0"; sockets="2"; cores="20"; threads="160"; mem_mb="262144"; idle="130"; active="290"; disktype="SAS/SSD"; disk_count="1"; eth_rate="10"; ib="EDR"; ib_rate="100"; opa_rate="0"; gpu_count="2"; gpu_model="Tesla_P100_SXM2_16GB"; gpu_mem="16384"; arch="ppc64le"
  fi

  # Single fixed CPU state. We did not model DVFS state switching.
  eps=$(awk -v i="$idle" -v a="$active" 'BEGIN{printf "%.6f",i+0.20*(a-i)}')
  pstate_speeds="${speed}"
  pstate_watts="${idle}:${eps}:${active}"

  mem_gb=$((mem_mb / 1024))
  cpucore=$((cores / sockets))
  memcore=$((mem_mb / cores))
  memcpu=$((mem_mb / sockets))
  exotic="NO"; [ "$arch" != "x86_64" ] && exotic="YES"

  cat >> "$BASE_DIR/platforms/grid5000_like_64nodes.xml" <<XML
    <host id="node-$i" speed="$pstate_speeds" core="$cores">
      <prop id="wattage_per_state" value="$pstate_watts"/>
      <prop id="wattage_off" value="8"/>
      <!-- Canonical Grid'5000/OAR properties -->
      <prop id="site" value="$site"/>
      <prop id="cluster" value="$cluster"/>
      <prop id="cpuarch" value="$arch"/>
      <prop id="cpu_vendor" value="$vendor"/>
      <prop id="cputype" value="$cputype"/>
      <prop id="cpu_count" value="$sockets"/>
      <prop id="core_count" value="$cores"/>
      <prop id="cpucore" value="$cpucore"/>
      <prop id="thread_count" value="$threads"/>
      <prop id="cpufreq" value="$cpufreq"/>
      <prop id="memnode" value="$mem_mb"/>
      <prop id="memcore" value="$memcore"/>
      <prop id="memcpu" value="$memcpu"/>
      <prop id="disk_reservation_count" value="$disk_count"/>
      <prop id="disktype" value="$disktype"/>
      <prop id="eth_count" value="1"/>
      <prop id="eth_rate" value="$eth_rate"/>
      <prop id="ib" value="$ib"/>
      <prop id="ib_count" value="$([ "$ib" = "NO" ] && echo 0 || echo 1)"/>
      <prop id="ib_rate" value="$ib_rate"/>
      <prop id="opa_count" value="$([ "$opa_rate" -gt 0 ] && echo 1 || echo 0)"/>
      <prop id="opa_rate" value="$opa_rate"/>
      <prop id="gpu_count" value="$gpu_count"/>
      <prop id="gpu_model" value="$gpu_model"/>
      <prop id="gpu_mem" value="$gpu_mem"/>
      <prop id="production" value="YES"/>
      <prop id="maintenance" value="NO"/>
      <prop id="besteffort" value="YES"/>
      <prop id="max_walltime" value="604800"/>
      <prop id="exotic" value="$exotic"/>
      <prop id="available" value="true"/>
      <!-- Scheduler input aliases -->
      <prop id="cores" value="$cores"/>
      <prop id="memory_gb" value="$mem_gb"/>
      <prop id="arch" value="$arch"/>
    </host>
XML
done
cat >> "$BASE_DIR/platforms/grid5000_like_64nodes.xml" <<'XML'
    <link id="backbone" bandwidth="100GBps" latency="10us"/>
XML
for i in $(seq 0 63); do
  for j in $(seq $((i+1)) 63); do
    echo "    <route src=\"node-$i\" dst=\"node-$j\"><link_ctn id=\"backbone\"/></route>" >> "$BASE_DIR/platforms/grid5000_like_64nodes.xml"
  done
done
cat >> "$BASE_DIR/platforms/grid5000_like_64nodes.xml" <<'XML'
  </zone>
</platform>
XML

# Platform inventory.
cat > "$BASE_DIR/platforms/grid5000_like_inventory.csv" <<'CSV'
node_id,site,cluster,cpuarch,cpu_vendor,cputype,cpu_count,core_count,thread_count,cpufreq_ghz,memnode_mb,disktype,disk_reservation_count,eth_rate_gbps,ib,ib_rate_gbps,opa_rate_gbps,gpu_count,gpu_model,gpu_mem_mb,idle_power_w,active_power_w
CSV
python3 - "$BASE_DIR/platforms/grid5000_like_64nodes.xml" "$BASE_DIR/platforms/grid5000_like_inventory.csv" <<'PYINV'
import csv, sys, xml.etree.ElementTree as ET
xml_path, out_path = sys.argv[1:]
root = ET.parse(xml_path).getroot()
fields = ["site","cluster","cpuarch","cpu_vendor","cputype","cpu_count","core_count","thread_count","cpufreq","memnode","disktype","disk_reservation_count","eth_rate","ib","ib_rate","opa_rate","gpu_count","gpu_model","gpu_mem"]
with open(out_path, "w", newline="") as f:
    w=csv.writer(f)
    w.writerow(["node_id","site","cluster","cpuarch","cpu_vendor","cputype","cpu_count","core_count","thread_count","cpufreq_ghz","memnode_mb","disktype","disk_reservation_count","eth_rate_gbps","ib","ib_rate_gbps","opa_rate_gbps","gpu_count","gpu_model","gpu_mem_mb","idle_power_w","active_power_w"])
    for host in root.findall('.//host'):
        p={x.attrib['id']:x.attrib['value'] for x in host.findall('prop')}
        watt=p.get('wattage_per_state','0:0').split(':')
        w.writerow([host.attrib['id']]+[p.get(k,'') for k in fields]+[watt[0],watt[-1]])
PYINV

cat > "$BASE_DIR/src/main.cpp" <<'CPP'
#include <simgrid/s4u.hpp>
#include <simgrid/plugins/energy.h>
#include <algorithm>
#include <cmath>
#include <chrono>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <map>
#include <memory>
#include <numeric>
#include <queue>
#include <set>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>
#include <unordered_map>
#include <unordered_set>

namespace sg4 = simgrid::s4u;
constexpr double EPS = 1e-9;

enum class Policy { FIFO, FIFO_MATCHING, EASY, CONSERVATIVE };

struct Node {
  int id{}; sg4::Host* host{}; double speed{}; int cores{}; double mem_gb{};
  std::string arch, site, cluster; double idle_power{}, active_power{}, off_power{}; int net_gbps{};
};
struct Job {
  int id{};
  int original_id{};
  double submit{};
  double observed_runtime{};
  int requested_processors{};
  double walltime{};
  double work_flops{};
  double requested_memory_mb{-1.0};
  std::string req_platform{"any"};
  std::string queue{"normal"};
};
struct CoreInterval { int job_id{}; double start{}, end{}; };
struct MemInterval { int job_id{}; double start{}, end{}, amount_mb{}; };
struct NodeShare { int node_id{}; int cores{}; };
struct Allocation {
  Job job; std::vector<NodeShare> shares; double start{}, end{}; bool backfilled{}, walltime_kill{};
};
struct Reservation { int job_id{}; std::vector<NodeShare> shares; double start{}, end{}; double mem_per_core_mb{}; };
struct Metrics {
  std::string scheduler;
  unsigned seed{};
  int submitted{}, completed{}, rejected{}, pending{};
  double makespan{}, energy{};
  double avg_wait{};
  double avg_turnaround{};
  double avg_slowdown{};
  double bounded_slowdown_tau10{};
  double bounded_slowdown_tau60{};
  double utilization{}, node_load_balance_jain{};
  double avg_allocated_nodes{}, avg_allocated_cores{};
  double multi_node_rate{}, same_cluster_rate{}, multi_cluster_rate{}, multi_site_rate{};
  int max_allocated_nodes{}, max_allocated_cores{};
  double scheduler_planning_wallclock_seconds{};
  int walltime_violations{}, backfilled{};
  std::string rejected_job_ids;
};
struct MatchDiagnostics {
  int candidates{}, nodes_used{}, clusters{}, sites{}, min_net{};
  std::string topology{"NONE"}, reason{"FIRST_FEASIBLE"};
};
struct SchedulerDiagnostics {
  double bounded_slowdown_tau10{};
  double bounded_slowdown_tau60{};
  double wait_p50{}, wait_p90{}, wait_p95{}, wait_p99{};
  double average_queue_length{};
  int maximum_queue_length{};
  double queued_time_area{};
  double idle_core_seconds_while_queued{};
  double average_idle_cores_while_queued{};
  double time_with_nonempty_queue{};
  double backfilled_core_seconds{};
  double completed_throughput{};
  int critical_job_id{-1}, critical_original_job_id{-1};
  double critical_submit{}, critical_start{}, critical_finish{}, critical_service{}, critical_wait{};
  int critical_processors{};
  bool critical_walltime_killed{};
};

static int prop_int(sg4::Host* h,const char* k,int d){const char* v=h->get_property(k);return v?std::stoi(v):d;}
static double prop_double(sg4::Host* h,const char* k,double d){const char* v=h->get_property(k);return v?std::stod(v):d;}
static std::string prop_str(sg4::Host* h,const char* k,const std::string& d){const char* v=h->get_property(k);return v?std::string(v):d;}
static std::pair<double,double> powers(sg4::Host* h){
  const char* v=h->get_property("wattage_per_state");
  if(!v) return {95,200};
  std::string profile(v);
  auto comma=profile.find(',');
  if(comma!=std::string::npos) profile=profile.substr(0,comma);
  std::vector<double> values;
  std::stringstream ss(profile);
  std::string token;
  while(std::getline(ss,token,':')) values.push_back(std::stod(token));
  if(values.size()>=3) return {values.front(),values.back()};
  if(values.size()==2) return {values[0],values[1]};
  if(values.size()==1) return {95,values[0]};
  return {95,200};
}
static int host_numeric_suffix(const std::string& name){
  const auto pos=name.find_last_of('-');
  if(pos==std::string::npos || pos+1>=name.size()) return std::numeric_limits<int>::max();
  try{return std::stoi(name.substr(pos+1));}
  catch(...){return std::numeric_limits<int>::max();}
}
static std::vector<Node> load_nodes(const std::vector<sg4::Host*>& hs){
  std::vector<sg4::Host*> ordered=hs;
  std::stable_sort(ordered.begin(),ordered.end(),[](sg4::Host* a,sg4::Host* b){
    const int na=host_numeric_suffix(a->get_name());
    const int nb=host_numeric_suffix(b->get_name());
    if(na!=nb) return na<nb;
    return a->get_name()<b->get_name();
  });
  std::vector<Node> out; out.reserve(ordered.size());
  for(size_t i=0;i<ordered.size();++i){
    auto* h=ordered[i];
    Node n; n.id=(int)i;n.host=h;n.speed=h->get_speed();n.cores=prop_int(h,"core_count",1);n.mem_gb=prop_double(h,"memnode",0)/1024.0;n.arch=prop_str(h,"cpuarch","x86_64");n.site=prop_str(h,"site","unknown");n.cluster=prop_str(h,"cluster","unknown");n.net_gbps=std::max({prop_int(h,"eth_rate",0),prop_int(h,"ib_rate",0),prop_int(h,"opa_rate",0)});auto p=powers(h);n.idle_power=p.first;n.active_power=p.second;n.off_power=prop_double(h,"wattage_off",8.0);out.push_back(n);
  }
  
  std::ifstream capf("data/real_workloads/platform_core_limit.txt");
  int limit=0; if(capf) capf>>limit;
  if(limit>0){
    int remaining=limit;
    for(auto& n:out){
      int keep=std::min(n.cores,std::max(0,remaining));
      n.cores=keep;
      remaining-=keep;
    }
    out.erase(std::remove_if(out.begin(),out.end(),[](const Node& n){return n.cores<=0;}),out.end());
    for(size_t i=0;i<out.size();++i) out[i].id=(int)i;
  }
  return out;
}
static void configure_energy_boundary(const std::vector<sg4::Host*>& all_hosts,
                                      const std::vector<Node>& selected_nodes){
  std::unordered_set<sg4::Host*> selected;
  for(const auto& node:selected_nodes) selected.insert(node.host);

  size_t powered_partition_hosts=0;
  size_t powered_off_hosts=0;
  for(auto* host:all_hosts){
    if(selected.count(host)){
      if(host->get_pstate_count()!=1){
        throw std::runtime_error(
          "fixed-state energy model requires exactly one pstate on "+host->get_name()+
          "; found "+std::to_string(host->get_pstate_count()));
      }
      ++powered_partition_hosts;
    }else{
      host->turn_off();
      ++powered_off_hosts;
    }
  }

  std::cout<<"ENERGY_BOUNDARY,SELECTED_HOSTS,"<<powered_partition_hosts
           <<",EXCLUDED_HOSTS,"<<powered_off_hosts
           <<",ACCOUNTING,SIMGRID_HOST_ENERGY_ONLY,FIXED_PSTATE,0\n";
}

static void write_energy_summary(const std::string& scheduler,unsigned seed,
                                  const std::vector<Allocation>& plan,
                                  const std::vector<Node>& selected_nodes,
                                  const std::vector<sg4::Host*>& all_hosts,
                                  double simulated_clock,
                                  const std::string& context_type,
                                  const std::string& context_a,
                                  const std::string& context_b){
  std::unordered_map<sg4::Host*,size_t> selected_index;
  for(size_t i=0;i<selected_nodes.size();++i) selected_index[selected_nodes[i].host]=i;

  std::vector<double> busy_core_seconds(selected_nodes.size(),0.0);
  std::vector<int> allocated_segments(selected_nodes.size(),0);
  std::vector<std::set<int>> allocated_jobs(selected_nodes.size());
  for(const auto& allocation:plan){
    const double duration=std::max(0.0,allocation.end-allocation.start);
    for(const auto& share:allocation.shares){
      if(share.node_id<0 || static_cast<size_t>(share.node_id)>=selected_nodes.size()) continue;
      busy_core_seconds[share.node_id]+=duration*share.cores;
      allocated_segments[share.node_id]++;
      allocated_jobs[share.node_id].insert(allocation.job.id);
    }
  }

  std::ofstream out("energy_summary.csv",std::ios::app);
  out.seekp(0,std::ios::end);
  if(out.tellp()==0){
    if(context_type=="window") out<<"window,load,"; else out<<"scenario,";
    out<<"scheduler,seed,host_id,selected_in_partition,simgrid_is_on,fixed_pstate,"
          "fixed_speed_flops_per_s,allocated_jobs,allocated_segments,busy_core_seconds,"
          "simulated_clock_s,simgrid_consumed_energy_j,included_in_total_energy\n";
  }
  out<<std::fixed<<std::setprecision(9);
  for(auto* host:all_hosts){
    const auto it=selected_index.find(host);
    const bool selected=it!=selected_index.end();
    const size_t idx=selected?it->second:0;
    if(context_type=="window") out<<context_a<<','<<context_b<<','; else out<<context_a<<',';
    out<<scheduler<<','<<seed<<','<<host->get_name()<<','<<(selected?1:0)<<','
       <<(host->is_on()?1:0)<<','<<host->get_pstate()<<','<<host->get_speed()<<','
       <<(selected?allocated_jobs[idx].size():0)<<','
       <<(selected?allocated_segments[idx]:0)<<','
       <<(selected?busy_core_seconds[idx]:0.0)<<','<<simulated_clock<<','
       <<sg_host_get_consumed_energy(host)<<','<<(selected?1:0)<<'\n';
  }
}

static std::string trim(std::string s){while(!s.empty()&&std::isspace((unsigned char)s.back()))s.pop_back();size_t i=0;while(i<s.size()&&std::isspace((unsigned char)s[i]))++i;return s.substr(i);}
static std::vector<Job> read_csv(const std::string& path,int limit){
  std::ifstream in(path); if(!in) throw std::runtime_error("cannot open workload: "+path);
  std::string line; std::getline(in,line); std::vector<Job> jobs;
  while(std::getline(in,line)&& (int)jobs.size()<limit){
    if(line.empty()) continue;
    std::stringstream ss(line); std::vector<std::string> c; std::string x;
    while(std::getline(ss,x,',')) c.push_back(trim(x));
    if(c.size()<7) continue;
    Job j;
    j.id=std::stoi(c[0]);
    j.submit=std::stod(c[1]);
    j.observed_runtime=std::stod(c[2]);
    j.requested_processors=std::max(1,std::stoi(c[3]));
    j.walltime=std::stod(c[4]);
    j.queue=c[5];
    j.work_flops=std::stod(c[6]);
    if(c.size()>7 && !c[7].empty()) j.requested_memory_mb=std::stod(c[7]);
    if(c.size()>8 && !c[8].empty() && c[8]!="-1") j.req_platform=c[8];
    j.original_id=c.size()>9?std::stoi(c[9]):j.id;
    if(j.submit<0||j.observed_runtime<=0||j.walltime<=0||j.work_flops<=0) continue;
    jobs.push_back(j);
  }
  std::stable_sort(jobs.begin(),jobs.end(),[](auto&a,auto&b){return a.submit==b.submit?a.id<b.id:a.submit<b.submit;});
  return jobs;
}


static std::string lower_copy(std::string x){
  std::transform(x.begin(),x.end(),x.begin(),[](unsigned char c){return std::tolower(c);});
  return x;
}
static bool node_matches_platform(const Node& n,const std::string& raw){
  std::string r=lower_copy(trim(raw));
  if(r.empty()||r=="-1"||r=="any"||r=="*") return true;
  // Supported OAR-style conjunction: key=value;key=value. Plain values match
  // architecture, cluster, or site. Unknown properties fail.
  std::stringstream ss(r); std::string term;
  while(std::getline(ss,term,';')){
    term=trim(term); if(term.empty()) continue;
    auto eq=term.find('=');
    if(eq==std::string::npos){
      if(term!=lower_copy(n.arch)&&term!=lower_copy(n.cluster)&&term!=lower_copy(n.site)) return false;
      continue;
    }
    std::string k=trim(term.substr(0,eq)),v=trim(term.substr(eq+1));
    if(k=="arch"||k=="cpuarch"||k=="architecture") { if(lower_copy(n.arch)!=v) return false; }
    else if(k=="cluster") { if(lower_copy(n.cluster)!=v) return false; }
    else if(k=="site") { if(lower_copy(n.site)!=v) return false; }
    else return false;
  }
  return true;
}
static double job_mem_per_core_mb(const Job& j){
  return j.requested_memory_mb>0 ? j.requested_memory_mb/std::max(1,j.requested_processors) : 0.0;
}

class CoreCalendar {
public:
  std::vector<Node> nodes;
  std::vector<std::vector<std::vector<CoreInterval>>> cal;
  std::vector<std::vector<MemInterval>> mem_cal;
  std::unordered_map<int,std::vector<std::pair<int,int>>> job_cores;

  explicit CoreCalendar(std::vector<Node> n):nodes(std::move(n)){
    cal.resize(nodes.size()); mem_cal.resize(nodes.size());
    for(const auto& x:nodes) cal[x.id].resize(x.cores);
  }

  bool core_free(int n,int c,double s,double e)const{
    const auto& intervals=cal[n][c];
    auto it=std::lower_bound(intervals.begin(),intervals.end(),e,
      [](const CoreInterval& in,double value){return in.start<value-EPS;});
    if(it!=intervals.begin()){
      const auto& prev=*std::prev(it);
      if(!(e<=prev.start+EPS||s>=prev.end-EPS)) return false;
    }
    if(it!=intervals.end() && !(e<=it->start+EPS||s>=it->end-EPS)) return false;
    return true;
  }

  int free_cores(int n,double s,double e)const{
    int k=0; for(int c=0;c<nodes[n].cores;++c) if(core_free(n,c,s,e)) ++k; return k;
  }
  double free_mem_mb(int n,double s,double e)const{
    double used=0.0;
    for(const auto& x:mem_cal[n]) if(!(e<=x.start+EPS||s>=x.end-EPS)) used+=x.amount_mb;
    return std::max(0.0,nodes[n].mem_gb*1024.0-used);
  }
  int feasible_cores_on_node(const Job& j,int n,double s,double e)const{
    if(!node_matches_platform(nodes[n],j.req_platform)) return 0;
    int cores=free_cores(n,s,e);
    const double mpc=job_mem_per_core_mb(j);
    if(mpc>0) cores=std::min(cores,(int)std::floor((free_mem_mb(n,s,e)+EPS)/mpc));
    return std::max(0,cores);
  }

  bool globally_feasible(const Job& j)const{
    int total=0; double mem=0.0;
    for(const auto& n:nodes) if(node_matches_platform(n,j.req_platform)){
      total+=n.cores; mem+=n.mem_gb*1024.0;
    }
    return total>=j.requested_processors && (j.requested_memory_mb<=0 || mem+EPS>=j.requested_memory_mb);
  }

  void reserve(int job,const std::vector<NodeShare>& a,double s,double e,double mem_per_core_mb=0.0){
    auto& slots=job_cores[job]; slots.clear();
    for(const auto& sh:a){
      int left=sh.cores;
      for(int c=0;c<nodes[sh.node_id].cores&&left>0;++c){
        if(core_free(sh.node_id,c,s,e)){
          auto& intervals=cal[sh.node_id][c];
          auto pos=std::lower_bound(intervals.begin(),intervals.end(),s,
            [](const CoreInterval& in,double value){return in.start<value;});
          intervals.insert(pos,{job,s,e}); slots.push_back({sh.node_id,c}); --left;
        }
      }
      if(left) throw std::runtime_error("core reservation inconsistency");
      const double amount=mem_per_core_mb*sh.cores;
      if(amount>0){
        if(amount>free_mem_mb(sh.node_id,s,e)+EPS) throw std::runtime_error("memory reservation inconsistency");
        mem_cal[sh.node_id].push_back({job,s,e,amount});
      }
    }
  }

  void unreserve(int job){
    auto it=job_cores.find(job);
    if(it!=job_cores.end()){
      for(const auto& slot:it->second){
        auto& v=cal[slot.first][slot.second];
        v.erase(std::remove_if(v.begin(),v.end(),[job](const CoreInterval& x){return x.job_id==job;}),v.end());
      }
      job_cores.erase(it);
    }
    for(auto& v:mem_cal) v.erase(std::remove_if(v.begin(),v.end(),[job](const MemInterval& x){return x.job_id==job;}),v.end());
  }

  double next_event(double now)const{
    double x=std::numeric_limits<double>::infinity();
    for(const auto&nc:cal) for(const auto&cc:nc) for(const auto&i:cc) if(i.end>now+EPS) x=std::min(x,i.end);
    return x;
  }
};
static int count_clusters(const std::vector<Node>& ns,const std::vector<NodeShare>& a){std::set<std::string>s;for(auto&x:a)s.insert(ns[x.node_id].cluster);return(int)s.size();}
static int count_sites(const std::vector<Node>& ns,const std::vector<NodeShare>& a){std::set<std::string>s;for(auto&x:a)s.insert(ns[x.node_id].site);return(int)s.size();}
static int min_net(const std::vector<Node>& ns,const std::vector<NodeShare>& a){int x=std::numeric_limits<int>::max();for(auto&v:a)x=std::min(x,ns[v.node_id].net_gbps);return a.empty()?0:x;}
static std::string topology(const std::vector<Node>& ns,const std::vector<NodeShare>& a){return count_clusters(ns,a)==1?"SAME_CLUSTER":count_sites(ns,a)==1?"SAME_SITE":"MULTI_SITE";}
static int total_cores(const std::vector<NodeShare>& a){int s=0;for(auto&x:a)s+=x.cores;return s;}
static double allocation_rate(const std::vector<Node>& nodes,const std::vector<NodeShare>& a){double r=0;for(const auto&x:a)r+=nodes[x.node_id].speed*x.cores;return r;}
static double predicted_runtime(const Job&j,const std::vector<Node>&nodes,const std::vector<NodeShare>&a){return j.work_flops/std::max(1e-12,allocation_rate(nodes,a));}

static bool first_fit_at(const CoreCalendar& c,const Job& j,double t,std::vector<NodeShare>& out){
  out.clear();int need=j.requested_processors;double e=t+j.walltime;
  for(const auto& n:c.nodes){int f=c.feasible_cores_on_node(j,n.id,t,e);if(f<=0)continue;int take=std::min(need,f);out.push_back({n.id,take});need-=take;if(need==0)return true;}out.clear();return false;
}
static std::vector<NodeShare> pack_from_order(const CoreCalendar& c,const Job& j,double t,const std::vector<int>& order){
  std::vector<NodeShare>a;int need=j.requested_processors;double e=t+j.walltime;for(int id:order){int f=c.feasible_cores_on_node(j,id,t,e);if(f<=0)continue;int take=std::min(need,f);a.push_back({id,take});need-=take;if(!need)break;}if(need)a.clear();return a;
}
static bool best_match_at(const CoreCalendar& c,const Job& j,double t,std::vector<NodeShare>& out,MatchDiagnostics* d){
  double e=t+j.walltime;std::vector<int> free;for(const auto&n:c.nodes)if(c.feasible_cores_on_node(j,n.id,t,e)>0)free.push_back(n.id);int capacity=0;for(int id:free)capacity+=c.feasible_cores_on_node(j,id,t,e);if(capacity<j.requested_processors){out.clear();return false;}
  std::vector<std::vector<NodeShare>> cand;std::vector<NodeShare> ff;if(first_fit_at(c,j,t,ff))cand.push_back(ff);
  std::map<std::string,std::vector<int>> byc,bys;for(int id:free){byc[c.nodes[id].cluster].push_back(id);bys[c.nodes[id].site].push_back(id);} 
  auto sorted=[&](std::vector<int> ids){std::stable_sort(ids.begin(),ids.end(),[&](int a,int b){int fa=c.feasible_cores_on_node(j,a,t,e),fb=c.feasible_cores_on_node(j,b,t,e);if(fa!=fb)return fa>fb;if(c.nodes[a].speed!=c.nodes[b].speed)return c.nodes[a].speed>c.nodes[b].speed;if(c.nodes[a].net_gbps!=c.nodes[b].net_gbps)return c.nodes[a].net_gbps>c.nodes[b].net_gbps;return a<b;});return ids;};
  for(auto&kv:byc){auto a=pack_from_order(c,j,t,sorted(kv.second));if(!a.empty())cand.push_back(a);}for(auto&kv:bys){auto a=pack_from_order(c,j,t,sorted(kv.second));if(!a.empty())cand.push_back(a);}auto g=pack_from_order(c,j,t,sorted(free));if(!g.empty())cand.push_back(g);
  auto canon=[](std::vector<NodeShare>a){std::sort(a.begin(),a.end(),[](auto&x,auto&y){return x.node_id<y.node_id;});return a;};
  std::set<std::string> seen;std::vector<std::vector<NodeShare>> uniq;for(auto a:cand){a=canon(a);std::ostringstream os;for(auto&s:a)os<<s.node_id<<':'<<s.cores<<';';if(seen.insert(os.str()).second)uniq.push_back(a);} 
  // Non-clairvoyant matching: use only resource information known before execution.
  auto key=[&](const std::vector<NodeShare>&a){
    std::vector<std::pair<int,int>> ids; for(auto&s:a) ids.push_back({s.node_id,s.cores});
    return std::tuple<int,int,int,double,int,std::vector<std::pair<int,int>>>(
      (int)a.size(), count_clusters(c.nodes,a), count_sites(c.nodes,a),
      -allocation_rate(c.nodes,a), -min_net(c.nodes,a), ids);
  };
  out=*std::min_element(uniq.begin(),uniq.end(),[&](auto&a,auto&b){return key(a)<key(b);});
  if(d){d->candidates=uniq.size();d->nodes_used=out.size();d->clusters=count_clusters(c.nodes,out);d->sites=count_sites(c.nodes,out);d->min_net=min_net(c.nodes,out);d->topology=topology(c.nodes,out);d->reason="MIN_NODES_THEN_CLUSTER_SITE_SPEED_NETWORK";}
  return true;
}
static bool select_at(const CoreCalendar& c,const Job&j,double t,bool match,std::vector<NodeShare>&a,MatchDiagnostics*d=nullptr){if(match)return best_match_at(c,j,t,a,d);bool ok=first_fit_at(c,j,t,a);if(ok&&d){d->candidates=1;d->nodes_used=a.size();d->clusters=count_clusters(c.nodes,a);d->sites=count_sites(c.nodes,a);d->min_net=min_net(c.nodes,a);d->topology=topology(c.nodes,a);d->reason="FIRST_FEASIBLE_CORE_ALLOCATION";}return ok;}
static double earliest_start(const CoreCalendar& c,const Job&j,double nb,bool match,
                             std::vector<NodeShare>&a,MatchDiagnostics*d=nullptr){
  // Feasible allocation changes only at nb or at the end of an existing
  // reservation.

  if(select_at(c,j,nb,match,a,d)) return nb;

  struct Cursor {
    double end;
    int node;
    int core;
    size_t index;
  };
  struct Later {
    bool operator()(const Cursor& x,const Cursor& y)const{
      if(std::fabs(x.end-y.end)>1e-8) return x.end>y.end;
      if(x.node!=y.node) return x.node>y.node;
      if(x.core!=y.core) return x.core>y.core;
      return x.index>y.index;
    }
  };

  std::priority_queue<Cursor,std::vector<Cursor>,Later> heap;

  for(size_t n=0;n<c.cal.size();++n){
    for(size_t core=0;core<c.cal[n].size();++core){
      const auto& intervals=c.cal[n][core];
      auto it=std::lower_bound(
        intervals.begin(),intervals.end(),nb-EPS,
        [](const CoreInterval& in,double value){return in.end<value;}
      );
      if(it!=intervals.end()){
        heap.push({it->end,static_cast<int>(n),static_cast<int>(core),
                   static_cast<size_t>(it-intervals.begin())});
      }
    }
  }

  double last_tested=nb;
  while(!heap.empty()){
    Cursor cur=heap.top();
    heap.pop();

    const double t=std::max(nb,cur.end);
    if(t>last_tested+1e-8){
      if(select_at(c,j,t,match,a,d)) return t;
      last_tested=t;
    }

    const auto& intervals=c.cal[cur.node][cur.core];
    const size_t next=cur.index+1;
    if(next<intervals.size())
      heap.push({intervals[next].end,cur.node,cur.core,next});
  }

  return std::numeric_limits<double>::infinity();
}

static std::vector<Reservation> reservation_plan(const std::deque<Job>&q,CoreCalendar c,double now,bool match){std::vector<Reservation>r;for(const auto&j:q){std::vector<NodeShare>a;double s=earliest_start(c,j,std::max(now,j.submit),match,a);if(!std::isfinite(s))continue;double e=s+j.walltime;c.reserve(j.id,a,s,e,job_mem_per_core_mb(j));r.push_back({j.id,a,s,e,job_mem_per_core_mb(j)});}return r;}
static bool conflicts(const std::vector<NodeShare>&a,double s,double e,const std::vector<Reservation>&r,int own,const std::vector<Node>&nodes){  
  for(const auto& u:a){
    int reserved=0;
    for(const auto& x:r){
      if(x.job_id==own || e<=x.start+EPS || s>=x.end-EPS) continue;
      for(const auto& v:x.shares) if(v.node_id==u.node_id) reserved+=v.cores;
    }
    if(u.cores+reserved>nodes[u.node_id].cores) return true;
    double reserved_mem=0.0;
    for(const auto& x:r){
      if(x.job_id==own || e<=x.start+EPS || s>=x.end-EPS) continue;
      for(const auto& v:x.shares) if(v.node_id==u.node_id) reserved_mem+=v.cores*x.mem_per_core_mb;
    }
    
    if(reserved_mem>nodes[u.node_id].mem_gb*1024.0+EPS) return true;
  }
  return false;
}

static std::string shares_str(const std::vector<NodeShare>&a){std::ostringstream os;for(size_t i=0;i<a.size();++i){if(i)os<<';';os<<a[i].node_id<<':'<<a[i].cores;}return os.str();}
static std::vector<Allocation> schedule(const std::vector<Job>&jobs,const std::vector<Node>&nodes,Policy p,const std::string&name,unsigned seed,std::ofstream&trace,int&rejected,int&pending,std::vector<std::pair<Job,std::string>>& rejected_jobs){
  CoreCalendar core(nodes);
  CoreCalendar guarantees(nodes);
  std::map<int,Reservation> guaranteed;
  std::map<int,double> running_actual_end;
  std::deque<Job>q;
  std::vector<Allocation>plan;
  size_t next=0;
  double now=jobs.empty()?0:jobs.front().submit;
  rejected=0;
  bool match=p==Policy::FIFO_MATCHING;

  auto ensure_guarantee=[&](const Job& j){
    if(p!=Policy::CONSERVATIVE || guaranteed.count(j.id)) return;
    std::vector<NodeShare>a;
    double s=earliest_start(guarantees,j,std::max(now,j.submit),false,a);
    if(!std::isfinite(s))
      throw std::runtime_error("failed to construct conservative reservation for feasible job");
    double e=s+j.walltime;
    guarantees.reserve(j.id,a,s,e,job_mem_per_core_mb(j));
    guaranteed[j.id]={j.id,a,s,e,job_mem_per_core_mb(j)};
  };

  // Conservative Backfilling.
  // Waiting-job reservations are persistent and are never postponed.
  // Released intervals may be reused when all reservation constraints remain valid.

  auto release_completed_guarantee_intervals=[&](){
    if(p!=Policy::CONSERVATIVE) return false;
    bool released=false;
    for(auto it=running_actual_end.begin();it!=running_actual_end.end();){
      if(it->second<=now+EPS){
        guarantees.unreserve(it->first);
        it=running_actual_end.erase(it);
        released=true;
      }else ++it;
    }
    return released;
  };

  // Conservative Backfilling invariant: every waiting job receives a
  // reservation at arrival, before any later job can be considered for an
  // early start. Existing reservations persist and are never delayed.

  auto try_start_with_guarantees=[&](const Job& j,std::vector<NodeShare>&a,MatchDiagnostics&md){
    auto it=guaranteed.find(j.id);
    Reservation own;
    bool had=it!=guaranteed.end();
    if(had){
      own=it->second;
      guarantees.unreserve(j.id);
    }
    bool ok=select_at(guarantees,j,now,false,a,&md);
    if(!ok && had)
      guarantees.reserve(own.job_id,own.shares,own.start,own.end,own.mem_per_core_mb);
    return ok;
  };

  auto dispatch=[&](const Job& j,const std::vector<NodeShare>&a,bool backfilled,
                    const std::string&decision,const MatchDiagnostics&md){
    const double predicted=predicted_runtime(j,nodes,a);
    const bool killed=predicted>j.walltime+EPS;
    const double dur=std::min(predicted,j.walltime);
    double end=now+dur;
    core.reserve(j.id,a,now,end,job_mem_per_core_mb(j));

    if(p==Policy::CONSERVATIVE){
      guarantees.unreserve(j.id);
      guaranteed.erase(j.id);
      // Running jobs remain in the conservative usage profile until their
      // user-supplied walltime estimate.  If they finish earlier, the interval
      // is removed at the actual completion event and the waiting schedule is
      // compressed.  
      guarantees.reserve(j.id,a,now,now+j.walltime,job_mem_per_core_mb(j));
      running_actual_end[j.id]=end;
    }

    plan.push_back({j,a,now,end,backfilled,killed});
    if((p==Policy::EASY || p==Policy::CONSERVATIVE) && plan.size()%1000==0){
      const char* label=(p==Policy::EASY)?"EASY":"Conservative";
      std::cerr<<"["<<label<<" progress] scheduled="<<plan.size()<<"/"<<jobs.size()
               <<" queue="<<q.size()<<" sim_time="<<now<<"\n";
    }

    // A job killed at its requested walltime was admitted and consumed
    // platform resources. It is therefore an execution failure, not an
    // admission rejection. It is counted only in walltime_violations
    // and remains visible in schedule_trace.csv as WALLTIME_KILLED.

    trace<<name<<','<<seed<<','<<j.id<<','<<j.original_id<<','<<j.submit<<','<<decision<<",,"
         <<j.requested_processors<<','<<total_cores(a)<<','<<shares_str(a)<<','
         <<now<<','<<end<<','<<j.observed_runtime<<','<<predicted<<','<<j.walltime<<','<<j.work_flops<<','
         <<md.candidates<<','<<md.nodes_used<<','<<md.clusters<<','<<md.sites<<','
         <<md.topology<<','<<md.reason<<','<<(killed?"WALLTIME_KILLED":"COMPLETED")<<"\n";
  };

  while(next<jobs.size()||!q.empty()){
    release_completed_guarantee_intervals();

    while(next<jobs.size()&&jobs[next].submit<=now+EPS){
      q.push_back(jobs[next]);
      if(p==Policy::CONSERVATIVE) ensure_guarantee(q.back());
      ++next;
    }

    if(q.empty()){
      if(next<jobs.size()) now=jobs[next].submit;
      continue;
    }

    for(auto it=q.begin();it!=q.end();){
      if(!core.globally_feasible(*it)){
        if(p==Policy::CONSERVATIVE){
          guarantees.unreserve(it->id);
          guaranteed.erase(it->id);
        }
        trace<<name<<','<<seed<<','<<it->id<<','<<it->original_id<<','<<it->submit
             <<",REJECTED,INFEASIBLE_RESOURCE_REQUEST,"
             <<it->requested_processors<<",0,,"<<now<<','<<now<<','
             <<it->observed_runtime<<",0,"<<it->walltime<<','<<it->work_flops
             <<",0,0,0,0,NONE,ADMISSION,REJECTED\n";
        rejected_jobs.push_back({*it,"INFEASIBLE_RESOURCE_REQUEST"});
        ++rejected;
        it=q.erase(it);
      }else ++it;
    }

    if(q.empty()) continue;

    bool done=false;
    std::vector<NodeShare>a;
    MatchDiagnostics md;

    bool head_ok=false;
    if(p==Policy::CONSERVATIVE){
      head_ok=try_start_with_guarantees(q.front(),a,md);
    }else{
      head_ok=select_at(core,q.front(),now,match,a,&md);
    }

    if(head_ok){
      Job j=q.front();
      q.pop_front();
      dispatch(j,a,false,"HEAD",md);
      done=true;
    }else if(p==Policy::EASY&&q.size()>1){
      std::vector<NodeShare>ha;
      double hs=earliest_start(core,q.front(),now,false,ha);
      if(std::isfinite(hs)){
        double he=hs+q.front().walltime;
        for(size_t i=1;i<q.size();++i){
          MatchDiagnostics x;
          if(!select_at(core,q[i],now,false,a,&x)) continue;
          double ce=now+q[i].walltime;
          bool bad=conflicts(a,now,ce,
                             std::vector<Reservation>{{q.front().id,ha,hs,he,job_mem_per_core_mb(q.front())}},
                             q[i].id,nodes);
          if(!bad){
            Job j=q[i];
            q.erase(q.begin()+i);
            dispatch(j,a,true,"EASY_BACKFILL",x);
            done=true;
            break;
          }
        }
      }
    }else if(p==Policy::CONSERVATIVE&&q.size()>1){
      for(size_t i=1;i<q.size();++i){
        MatchDiagnostics x;
        if(!try_start_with_guarantees(q[i],a,x)) continue;
        Job j=q[i];
        q.erase(q.begin()+i);
        dispatch(j,a,true,"CONS_BACKFILL",x);
        done=true;
        break;
      }
    }

    if(!done){
      double ev=core.next_event(now);
      if(next<jobs.size()) ev=std::min(ev,jobs[next].submit);
      if(!std::isfinite(ev)) break;
      now=std::max(now+EPS,ev);
    }
  }

  pending=q.size()+(jobs.size()-next);
  return plan;
}
static std::string rejected_ids_string(const std::vector<std::pair<Job,std::string>>& rejected_jobs){
  std::ostringstream os;
  for(size_t i=0;i<rejected_jobs.size();++i){
    if(i) os<<';';
    os<<rejected_jobs[i].first.id;
  }
  return os.str();
}

static void write_rejected_jobs(const std::string& scheduler,unsigned seed,
                                const std::vector<std::pair<Job,std::string>>& rejected_jobs,
                                const std::string& context_type,
                                const std::string& context_a,
                                const std::string& context_b){
  std::ofstream out("rejected_jobs.csv",std::ios::app);
  out.seekp(0,std::ios::end);
  if(out.tellp()==0){
    if(context_type=="window") out<<"window,load,";
    else out<<"scenario,";
    out<<"scheduler,seed,job_id,original_job_id,submit_time,observed_runtime,"
          "requested_processors,requested_walltime,requested_memory_mb,queue,"
          "requested_platform,rejection_reason\n";
  }
  out<<std::fixed<<std::setprecision(6);
  for(const auto& item:rejected_jobs){
    const Job& j=item.first;
    if(context_type=="window") out<<context_a<<','<<context_b<<',';
    else out<<context_a<<',';
    out<<scheduler<<','<<seed<<','<<j.id<<','<<j.original_id<<','<<j.submit<<','
       <<j.observed_runtime<<','<<j.requested_processors<<','<<j.walltime<<','
       <<j.requested_memory_mb<<','<<j.queue<<','<<j.req_platform<<','<<item.second<<'\n';
  }
}

static Metrics calc(const std::string&n,unsigned seed,int sub,int rej,int pend,
                    const std::vector<Allocation>&p,const std::vector<Node>&nodes,
                    double planning_seconds){
  Metrics m;
  m.scheduler=n; m.seed=seed; m.submitted=sub; m.completed=std::count_if(p.begin(),p.end(),[](const Allocation& a){return !a.walltime_kill;});
  m.rejected=rej; m.pending=pend;
  m.scheduler_planning_wallclock_seconds=planning_seconds;
  if(p.empty()) return m;

  double t0=std::numeric_limits<double>::infinity(),last=0,turn=0,busy=0;
  double nodes_sum=0,cores_sum=0;
  int multi_node=0,same_cluster=0,multi_cluster=0,multi_site=0;
  std::vector<double> waits,slowdowns,bounded10,bounded60,node_work(nodes.size(),0.0);
  waits.reserve(p.size()); slowdowns.reserve(p.size());
  bounded10.reserve(p.size()); bounded60.reserve(p.size());

  for(const auto&a:p){
    t0=std::min(t0,a.job.submit);
    last=std::max(last,a.end);
    const double service=std::max(1e-6,a.end-a.start);
    const double wait=a.start-a.job.submit;
    const double turnaround=a.end-a.job.submit;
    waits.push_back(wait);
    slowdowns.push_back(turnaround/service);
    if(!a.walltime_kill){      
      bounded10.push_back(std::max(1.0,turnaround/std::max(service,10.0)));
      bounded60.push_back(std::max(1.0,turnaround/std::max(service,60.0)));
    }
    turn+=turnaround;
    busy+=service*total_cores(a.shares);
    const int allocated_nodes=static_cast<int>(a.shares.size());
    const int allocated_cores=total_cores(a.shares);
    nodes_sum+=allocated_nodes;
    cores_sum+=allocated_cores;
    m.max_allocated_nodes=std::max(m.max_allocated_nodes,allocated_nodes);
    m.max_allocated_cores=std::max(m.max_allocated_cores,allocated_cores);
    if(allocated_nodes>1) ++multi_node;

    std::set<std::string> clusters,sites;
    for(const auto&x:a.shares){
      clusters.insert(nodes[x.node_id].cluster);
      sites.insert(nodes[x.node_id].site);
      node_work[x.node_id]+=service*x.cores;
    }
    if(clusters.size()==1) ++same_cluster;
    if(clusters.size()>1) ++multi_cluster;
    if(sites.size()>1) ++multi_site;
    if(a.walltime_kill) ++m.walltime_violations;
    if(a.backfilled) ++m.backfilled;
  }

  m.makespan=last-t0;
  m.avg_wait=std::accumulate(waits.begin(),waits.end(),0.0)/p.size();
  m.avg_turnaround=turn/p.size();
  m.avg_slowdown=std::accumulate(slowdowns.begin(),slowdowns.end(),0.0)/p.size();
  m.bounded_slowdown_tau10=bounded10.empty()?0.0:
    std::accumulate(bounded10.begin(),bounded10.end(),0.0)/bounded10.size();
  m.bounded_slowdown_tau60=bounded60.empty()?0.0:
    std::accumulate(bounded60.begin(),bounded60.end(),0.0)/bounded60.size();

  int total_capacity=0;
  for(const auto&x:nodes) total_capacity+=x.cores;
  m.utilization=busy/std::max(1e-9,m.makespan*total_capacity);

  const double sum=std::accumulate(node_work.begin(),node_work.end(),0.0);
  double sq=0; for(double x:node_work) sq+=x*x;
  m.node_load_balance_jain=sq?sum*sum/(nodes.size()*sq):1.0;

  m.avg_allocated_nodes=nodes_sum/p.size();
  m.avg_allocated_cores=cores_sum/p.size();
  m.multi_node_rate=static_cast<double>(multi_node)/p.size();
  m.same_cluster_rate=static_cast<double>(same_cluster)/p.size();
  m.multi_cluster_rate=static_cast<double>(multi_cluster)/p.size();
  m.multi_site_rate=static_cast<double>(multi_site)/p.size();
  return m;
}
static double percentile(std::vector<double> values,double q){
  if(values.empty()) return 0.0;
  std::sort(values.begin(),values.end());
  const double pos=q*static_cast<double>(values.size()-1);
  const auto lo=static_cast<std::size_t>(std::floor(pos));
  const auto hi=static_cast<std::size_t>(std::ceil(pos));
  if(lo==hi) return values[lo];
  const double f=pos-static_cast<double>(lo);
  return values[lo]*(1.0-f)+values[hi]*f;
}

static SchedulerDiagnostics diagnose_schedule(const std::vector<Job>&jobs,
                                               const std::vector<Allocation>&plan,
                                               const std::vector<Node>&nodes){
  SchedulerDiagnostics d;
  if(plan.empty()) return d;

  int capacity=0;
  for(const auto&n:nodes) capacity+=n.cores;

  double first_submit=std::numeric_limits<double>::infinity();
  double last_finish=0.0;
  double bsd10=0.0,bsd60=0.0;
  int completed_count=0;
  std::vector<double> completed_waits;

  struct Event { double t{}; int queue_delta{}; int active_core_delta{}; };
  std::vector<Event> events;
  events.reserve(plan.size()*3);

  const Allocation* critical=nullptr;
  for(const auto&a:plan){
    first_submit=std::min(first_submit,a.job.submit);
    last_finish=std::max(last_finish,a.end);
    if(!critical || a.end>critical->end ||
       (std::fabs(a.end-critical->end)<=1e-9 && a.job.id<critical->job.id)) critical=&a;

    const double service=std::max(1e-9,a.end-a.start);
    const double wait=std::max(0.0,a.start-a.job.submit);
    const int cores=total_cores(a.shares);
    events.push_back({a.job.submit,+1,0});
    events.push_back({a.start,-1,+cores});
    events.push_back({a.end,0,-cores});

    if(a.backfilled) d.backfilled_core_seconds+=service*cores;
    if(!a.walltime_kill){
      ++completed_count;
      completed_waits.push_back(wait);
      bsd10+=std::max(1.0,(wait+service)/std::max(service,10.0));
      bsd60+=std::max(1.0,(wait+service)/std::max(service,60.0));
    }
  }

  d.bounded_slowdown_tau10=completed_count?bsd10/completed_count:0.0;
  d.bounded_slowdown_tau60=completed_count?bsd60/completed_count:0.0;
  d.wait_p50=percentile(completed_waits,0.50);
  d.wait_p90=percentile(completed_waits,0.90);
  d.wait_p95=percentile(completed_waits,0.95);
  d.wait_p99=percentile(completed_waits,0.99);

  std::sort(events.begin(),events.end(),[](const Event&a,const Event&b){return a.t<b.t;});
  int queued=0,active_cores=0;
  double previous=events.front().t;
  for(std::size_t i=0;i<events.size();){
    const double now=events[i].t;
    const double dt=std::max(0.0,now-previous);
    d.queued_time_area+=dt*queued;
    if(queued>0){
      const int idle=std::max(0,capacity-active_cores);
      d.time_with_nonempty_queue+=dt;
      d.idle_core_seconds_while_queued+=dt*idle;
    }
    int qdelta=0,cdelta=0;
    while(i<events.size() && std::fabs(events[i].t-now)<=1e-9){
      qdelta+=events[i].queue_delta;
      cdelta+=events[i].active_core_delta;
      ++i;
    }
    queued+=qdelta;
    active_cores+=cdelta;
    if(queued<0) throw std::runtime_error("negative queue length in diagnostics");
    if(active_cores<0 || active_cores>capacity)
      throw std::runtime_error("invalid active-core count in diagnostics");
    d.maximum_queue_length=std::max(d.maximum_queue_length,queued);
    previous=now;
  }

  const double horizon=std::max(1e-9,last_finish-first_submit);
  d.average_queue_length=d.queued_time_area/horizon;
  d.average_idle_cores_while_queued=d.time_with_nonempty_queue>0.0?
    d.idle_core_seconds_while_queued/d.time_with_nonempty_queue:0.0;
  d.completed_throughput=completed_count/horizon;

  if(critical){
    d.critical_job_id=critical->job.id;
    d.critical_original_job_id=critical->job.original_id;
    d.critical_submit=critical->job.submit;
    d.critical_start=critical->start;
    d.critical_finish=critical->end;
    d.critical_service=critical->end-critical->start;
    d.critical_wait=critical->start-critical->job.submit;
    d.critical_processors=total_cores(critical->shares);
    d.critical_walltime_killed=critical->walltime_kill;
  }
  return d;
}

static void write_scheduler_diagnostics(const Metrics&m,const SchedulerDiagnostics&d,
                                        const std::string&context_type,
                                        const std::string&context_a,
                                        const std::string&context_b){
  std::ofstream o("scheduler_diagnostics.csv",std::ios::app);
  o.seekp(0,std::ios::end);
  if(o.tellp()==0)
    o<<"context_type,context_a,context_b,scheduler,seed,bounded_slowdown_tau10,"
       "bounded_slowdown_tau60,wait_p50,wait_p90,wait_p95,wait_p99,"
       "average_queue_length,maximum_queue_length,queued_time_area,"
       "time_with_nonempty_queue,idle_core_seconds_while_queued,"
       "average_idle_cores_while_queued,backfilled_core_seconds,"
       "completed_throughput,critical_job_id,critical_original_job_id,"
       "critical_submit,critical_start,critical_finish,critical_service,"
       "critical_wait,critical_processors,critical_execution_status\n";
  o<<std::fixed<<std::setprecision(9)
   <<context_type<<','<<context_a<<','<<context_b<<','<<m.scheduler<<','<<m.seed<<','
   <<d.bounded_slowdown_tau10<<','<<d.bounded_slowdown_tau60<<','
   <<d.wait_p50<<','<<d.wait_p90<<','<<d.wait_p95<<','<<d.wait_p99<<','
   <<d.average_queue_length<<','<<d.maximum_queue_length<<','<<d.queued_time_area<<','
   <<d.time_with_nonempty_queue<<','<<d.idle_core_seconds_while_queued<<','
   <<d.average_idle_cores_while_queued<<','<<d.backfilled_core_seconds<<','
   <<d.completed_throughput<<','<<d.critical_job_id<<','<<d.critical_original_job_id<<','
   <<d.critical_submit<<','<<d.critical_start<<','<<d.critical_finish<<','
   <<d.critical_service<<','<<d.critical_wait<<','<<d.critical_processors<<','
   <<(d.critical_walltime_killed?"WALLTIME_KILLED":"COMPLETED")<<'\n';
}

static void write_critical_tail(const std::string&scheduler,unsigned seed,
                                const std::vector<Allocation>&plan,
                                const std::string&context_type,
                                const std::string&context_a,
                                const std::string&context_b){
  std::vector<const Allocation*> tail;
  tail.reserve(plan.size());
  for(const auto&a:plan) tail.push_back(&a);
  std::sort(tail.begin(),tail.end(),[](const Allocation*a,const Allocation*b){
    if(a->end!=b->end) return a->end>b->end;
    return a->job.id<b->job.id;
  });
  if(tail.size()>20) tail.resize(20);
  std::ofstream o("makespan_tail_jobs.csv",std::ios::app);
  o.seekp(0,std::ios::end);
  if(o.tellp()==0)
    o<<"context_type,context_a,context_b,scheduler,seed,finish_rank,job_id,"
       "original_job_id,submit,start,finish,wait,service,allocated_processors,"
       "backfilled,execution_status\n";
  int rank=1;
  for(const auto*a:tail){
    o<<std::fixed<<std::setprecision(9)
     <<context_type<<','<<context_a<<','<<context_b<<','<<scheduler<<','<<seed<<','
     <<rank++<<','<<a->job.id<<','<<a->job.original_id<<','<<a->job.submit<<','
     <<a->start<<','<<a->end<<','<<(a->start-a->job.submit)<<','<<(a->end-a->start)<<','
     <<total_cores(a->shares)<<','<<(a->backfilled?1:0)<<','
     <<(a->walltime_kill?"WALLTIME_KILLED":"COMPLETED")<<'\n';
  }
}

static double planned_end_time(const std::vector<Allocation>&p){
  double x=0;
  for(const auto&a:p) x=std::max(x,a.end);
  return x;
}

static void execute_plan(const std::vector<Allocation>&p,const std::vector<Node>&nodes){
  // Parallel execution model:
  // one SimGrid actor is created for every allocated node segment, and each
  // segment uses thread_execute(..., allocated_cores_on_node). All segments
  // belonging to the same job start at the same simulated instant. The CPU
  // state remains fixed at pstate 0 for the entire simulation.
  for(const auto& n:nodes){
    if(n.host->get_pstate_count()!=1 || n.host->get_pstate()!=0)
      throw std::runtime_error("host "+n.host->get_name()+" is not in the required fixed pstate 0");
  }

  for(const auto&a:p){
    const double dur=a.end-a.start;
    for(const auto&s:a.shares){
      const double st=a.start;
      const int threads=std::max(1,s.cores);
      sg4::Host* host=nodes[s.node_id].host;
      // thread_execute's flop amount is per thread. 
      const double flops_per_thread=host->get_speed()*dur;
      sg4::Actor::create(
        "job_"+std::to_string(a.job.id)+"_n_"+std::to_string(s.node_id),
        host,
        [st,flops_per_thread,threads,host](){
          sg4::this_actor::sleep_until(st);
          sg4::this_actor::thread_execute(host,flops_per_thread,threads);
        });
    }
  }
}
static std::pair<Policy,std::string> policy(const std::string&s){if(s=="fifo")return{Policy::FIFO,"FIFO"};if(s=="fifo_matching")return{Policy::FIFO_MATCHING,"FIFO_with_Matching"};if(s=="easy_backfilling")return{Policy::EASY,"EASY_Backfilling"};if(s=="conservative_backfilling")return{Policy::CONSERVATIVE,"Conservative_Backfilling"};throw std::runtime_error("unknown policy");}
static void write_result(const Metrics&m){
  std::ofstream o("results.csv",std::ios::app);
  o.seekp(0,std::ios::end);
  if(o.tellp()==0)
    o<<"scheduler,seed,submitted_jobs,completed_jobs,rejected_jobs,pending_jobs,"
       "makespan,total_energy,avg_wait,avg_turnaround,avg_slowdown,"
       "bounded_slowdown_tau10,bounded_slowdown_tau60,"
       "utilization,energy_per_completed_job,walltime_violations,"
       "backfilled_jobs,backfill_rate,node_load_balance_jain,"
       "avg_allocated_nodes,avg_allocated_cores,multi_node_rate,"
       "same_cluster_rate,multi_cluster_rate,multi_site_rate,"
       "max_allocated_nodes,max_allocated_cores,"
       "scheduler_planning_wallclock_seconds,rejected_job_ids\n";

  o<<std::fixed<<std::setprecision(9)
   <<m.scheduler<<','<<m.seed<<','<<m.submitted<<','<<m.completed<<','
   <<m.rejected<<','<<m.pending<<','<<m.makespan<<','<<m.energy<<','
   <<m.avg_wait<<','<<m.avg_turnaround<<','<<m.avg_slowdown<<','
   <<m.bounded_slowdown_tau10<<','<<m.bounded_slowdown_tau60<<','
   <<m.utilization<<','
   <<(m.completed?m.energy/m.completed:0.0)<<','
   <<m.walltime_violations<<','<<m.backfilled<<','
   <<((m.completed+m.walltime_violations)>0?static_cast<double>(m.backfilled)/(m.completed+m.walltime_violations):0.0)<<','
   <<m.node_load_balance_jain<<','<<m.avg_allocated_nodes<<','<<m.avg_allocated_cores<<','
   <<m.multi_node_rate<<','<<m.same_cluster_rate<<','<<m.multi_cluster_rate<<','<<m.multi_site_rate<<','
   <<m.max_allocated_nodes<<','<<m.max_allocated_cores<<','
   <<m.scheduler_planning_wallclock_seconds<<','<<m.rejected_job_ids<<'\n';
}
int main(int argc,char**argv){
  std::string pa=argc>1?argv[1]:"fifo";
  unsigned seed=argc>2?std::stoul(argv[2]):42;
  int n=argc>3?std::stoi(argv[3]):10000;
  std::string csv=argc>4?argv[4]:"data/real_workloads/current_oar_workload.csv";
  std::string context_type=argc>5?argv[5]:"general";
  std::string context_a=argc>6?argv[6]:"unspecified";
  std::string context_b=argc>7?argv[7]:"";
  if(context_type!="general" && context_type!="window")
    throw std::runtime_error("context type must be 'general' or 'window'");

  sg_host_energy_plugin_init();
  sg4::Engine e(&argc,argv);
  e.load_platform("platforms/grid5000_like_64nodes.xml");

  const auto all_hosts=e.get_all_hosts();
  auto nodes=load_nodes(all_hosts);
  configure_energy_boundary(all_hosts,nodes);
  auto jobs=read_csv(csv,n);
  auto [pol,name]=policy(pa);

  std::ofstream tr("schedule_trace.csv",std::ios::app);
  tr<<std::fixed<<std::setprecision(6);
  tr.seekp(0,std::ios::end);
  if(tr.tellp()==0)
    tr<<"scheduler,seed,job_id,original_job_id,submit_time,decision,rejection_reason,"
         "requested_processors,allocated_processors,node_core_allocation,start,end,"
         "observed_runtime,predicted_runtime,requested_walltime,work_flops,matching_candidates,allocated_nodes,"
         "allocated_clusters,allocated_sites,topology_class,selection_reason,execution_status\n";

  int r=0,p=0;
  std::vector<std::pair<Job,std::string>> rejected_jobs;
  const auto planning_begin=std::chrono::steady_clock::now();
  auto plan=schedule(jobs,nodes,pol,name,seed,tr,r,p,rejected_jobs);
  const auto planning_end=std::chrono::steady_clock::now();
  const double planning_seconds=
    std::chrono::duration<double>(planning_end-planning_begin).count();
  auto m=calc(name,seed,jobs.size(),r,p,plan,nodes,planning_seconds);
  m.rejected_job_ids=rejected_ids_string(rejected_jobs);
  const auto diagnostics=diagnose_schedule(jobs,plan,nodes);
  
  // Admission rejections never execute; walltime violations are admitted jobs that ran
  // and were killed at their requested walltime.
  const int accounted=m.completed+m.rejected+m.walltime_violations+m.pending;
  if(accounted!=m.submitted){
    throw std::runtime_error(
      "job accounting mismatch: submitted="+std::to_string(m.submitted)+
      " completed="+std::to_string(m.completed)+
      " rejected="+std::to_string(m.rejected)+
      " walltime_violations="+std::to_string(m.walltime_violations)+
      " pending="+std::to_string(m.pending));
  }

  write_rejected_jobs(name,seed,rejected_jobs,context_type,context_a,context_b);

  const double expected_clock=planned_end_time(plan);
  execute_plan(plan,nodes);
  e.run();

  const double simulated_clock=sg4::Engine::get_clock();
  const double tolerance=std::max(1e-6,expected_clock*1e-6);
  if(std::fabs(simulated_clock-expected_clock)>tolerance){
    std::cerr<<"ERROR: SimGrid execution clock mismatch: planned_end="
             <<expected_clock<<" simulated_end="<<simulated_clock
             <<" tolerance="<<tolerance<<"\n";
    return 3;
  }

  // Total energy is the energy integrated by SimGrid's host-energy
  // plugin during the replay.
  m.energy=0.0;
  for(const auto& node:nodes) m.energy+=sg_host_get_consumed_energy(node.host);
  write_energy_summary(name,seed,plan,nodes,all_hosts,simulated_clock,
                       context_type,context_a,context_b);

  std::cout<<std::fixed<<std::setprecision(6)
           <<"SCHEDULER,"<<m.scheduler
           <<",SEED,"<<m.seed
           <<",SUBMITTED,"<<m.submitted
           <<",COMPLETED,"<<m.completed
           <<",REJECTED,"<<m.rejected
           <<",PENDING,"<<m.pending
           <<",MAKESPAN,"<<m.makespan
           <<",ENERGY,"<<m.energy
           <<",AVG_WAIT,"<<m.avg_wait
           <<",UTILIZATION,"<<m.utilization
           <<",WALLTIME_VIOLATIONS,"<<m.walltime_violations
           <<",BACKFILLED,"<<m.backfilled
           <<",NODE_LOAD_BALANCE_JAIN,"<<m.node_load_balance_jain
           <<",AVG_ALLOCATED_NODES,"<<m.avg_allocated_nodes
           <<",AVG_ALLOCATED_CORES,"<<m.avg_allocated_cores
           <<",MULTI_NODE_RATE,"<<m.multi_node_rate
           <<",MULTI_CLUSTER_RATE,"<<m.multi_cluster_rate
           <<",MULTI_SITE_RATE,"<<m.multi_site_rate
           <<",PLANNING_SECONDS,"<<m.scheduler_planning_wallclock_seconds
           <<",SIMGRID_CLOCK,"<<simulated_clock<<"\n";

  write_result(m);
  write_scheduler_diagnostics(m,diagnostics,context_type,context_a,context_b);
  write_critical_tail(name,seed,plan,context_type,context_a,context_b);
  return 0;
}


CPP

cat > "$BASE_DIR/CMakeLists.txt" <<'CMAKE'
cmake_minimum_required(VERSION 3.10)
project(oar_simgrid_v1)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SIMGRID REQUIRED simgrid)
add_executable(oar_hpc_energy src/main.cpp)
target_include_directories(oar_hpc_energy PRIVATE ${SIMGRID_INCLUDE_DIRS})
target_link_libraries(oar_hpc_energy ${SIMGRID_LIBRARIES} pthread dl)
CMAKE

cat > "$BASE_DIR/workload_common.py" <<'PYCOMMON'
#!/usr/bin/env python3
from __future__ import annotations
import csv, hashlib, json, math, os, pathlib, random, statistics, urllib.request, zipfile
from collections import Counter

URL="https://atlarge-research.com/gwa-traces/gwa_t_2_anon_jobs_gwf.zip"
ROOT=pathlib.Path("data/real_workloads")
RAW=ROOT/"raw/grid5000_gwa_t2/gwa_t_2_anon_jobs_gwf.zip"
GLOBAL=ROOT/"all_valid_jobs_global.csv"
REF_SPEED=2.65e9


def ensure_raw(explicit=None):
    if explicit:
        q=pathlib.Path(explicit)
        if not q.is_file(): raise SystemExit(f"RAW_WORKLOAD_FILE not found: {q}")
        return q
    if RAW.is_file() and RAW.stat().st_size>1024:
        print(f"[workload] cached raw trace found: {RAW}")
        return RAW
    RAW.parent.mkdir(parents=True,exist_ok=True)
    tmp=RAW.with_suffix(".part")
    req=urllib.request.Request(URL,headers={"User-Agent":"Mozilla/5.0"})
    print(f"[workload] downloading {URL}")
    with urllib.request.urlopen(req,timeout=180) as r, tmp.open("wb") as f:
        while block:=r.read(1024*1024): f.write(block)
    tmp.replace(RAW)
    return RAW


def platform_capacity():
    inv=pathlib.Path("platforms/grid5000_like_inventory.csv")
    rows=list(csv.DictReader(inv.open(newline=""))) if inv.is_file() else []
    cap=sum(int(float(r["core_count"])) for r in rows)
    if cap<=0: raise SystemExit("Invalid or missing platform inventory")
    return cap


def iter_raw_jobs(raw):
    mode=os.environ.get("PROCESSOR_REPLAY_MODE","allocated").strip().lower()
    if mode not in {"allocated","requested_or_allocated"}:
        raise SystemExit("PROCESSOR_REPLAY_MODE must be allocated or requested_or_allocated")
    with zipfile.ZipFile(raw) as z, z.open("grid5000_clean_trace.log") as f:
        for b in f:
            s=b.decode("utf-8",errors="ignore").strip()
            if not s or s.startswith("#"): continue
            p=s.split("\t")
            if len(p)<29: continue
            try:
                jid=int(p[0]); submit=int(p[1]); run=int(p[3]); nproc=int(p[4])
                reqp=int(p[7]); reqt=int(p[8]); reqmem=int(p[9]); status=int(p[10])
            except ValueError: continue
            if status!=1 or submit<0 or run<=0 or nproc<=0 or reqt<=0: continue
            replay=reqp if mode=="requested_or_allocated" and reqp>0 else nproc
            yield {"original_job_id":jid,"original_submit_time":submit,
                   "observed_runtime":run,"allocated_processors":nproc,
                   "requested_processors_raw":reqp,"replay_processors":replay,
                   "requested_walltime":reqt,"requested_memory_mb":reqmem,
                   "queue":p[14].strip() or "normal",
                   "original_cluster":p[17].strip() or "unknown",
                   "req_platform_raw":p[23].strip() or "any",
                   "processor_time":replay*run,
                   "work_flops":float(run)*replay*REF_SPEED}


def build_all_valid_global(raw, force=False):
    """Cache every valid completed job from the raw trace without class filtering."""
    jobs=list(iter_raw_jobs(raw))
    if not jobs:
        raise SystemExit("No valid completed jobs found in GWA-T-2")
    unique={j["original_job_id"]:j for j in jobs}
    jobs=list(unique.values())
    jobs.sort(key=lambda j:(j["original_submit_time"],j["original_job_id"]))
    GLOBAL.parent.mkdir(parents=True,exist_ok=True)
    fields=list(jobs[0])
    with GLOBAL.open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(jobs)
    meta={
        "criterion":"all valid completed raw-trace jobs; no demand-class prefilter",
        "raw_valid_jobs":len(jobs),
        "global_jobs":len(jobs),
        "sha256":hashlib.sha256(GLOBAL.read_bytes()).hexdigest(),
    }
    (ROOT/"all_valid_jobs_global.metadata.json").write_text(
        json.dumps(meta,indent=2,sort_keys=True)+"\n"
    )
    return jobs,meta


def load_or_build_global(raw,q=0.80,force=False):
    """Compatibility wrapper: q is ignored because all valid raw jobs are used."""
    meta_path=ROOT/"all_valid_jobs_global.metadata.json"
    if force or not GLOBAL.is_file() or not meta_path.is_file():
        return build_all_valid_global(raw,force=True)
    jobs=[]
    for r in csv.DictReader(GLOBAL.open(newline="")):
        d={k:r[k] for k in r}
        for k in ("original_job_id","original_submit_time","observed_runtime","allocated_processors",
                  "requested_processors_raw","replay_processors","requested_walltime","requested_memory_mb"):
            d[k]=int(float(d[k]))
        for k in ("processor_time","work_flops"):
            d[k]=float(d[k])
        jobs.append(d)
    return jobs,json.loads(meta_path.read_text())


def weighted_random_permutation(population,seed):
    """Return a reproducible weighted random permutation without replacement.

    Every valid raw job is eligible. Selection is still random, but tiny jobs
    receive lower probability. The weight combines processor time, runtime and
    processor count on logarithmic robust scales, with a positive floor so no
    valid job is impossible to select.
    """
    if not population:
        raise SystemExit("Cannot sample from an empty raw workload")
    rng=random.Random(seed)
    pts=[math.log1p(max(0.0,float(j["processor_time"]))) for j in population]
    rts=[math.log1p(max(0.0,float(j["observed_runtime"]))) for j in population]
    pcs=[math.log1p(max(0.0,float(j["replay_processors"]))) for j in population]

    def robust_scale(values):
        ordered=sorted(values)
        lo=ordered[int(0.10*(len(ordered)-1))]
        hi=ordered[int(0.90*(len(ordered)-1))]
        span=max(1e-12,hi-lo)
        return lo,span

    pt_lo,pt_span=robust_scale(pts)
    rt_lo,rt_span=robust_scale(rts)
    pc_lo,pc_span=robust_scale(pcs)

    keyed=[]
    for j,pt,rt,pc in zip(population,pts,rts,pcs):
        npt=min(1.5,max(0.0,(pt-pt_lo)/pt_span))
        nrt=min(1.5,max(0.0,(rt-rt_lo)/rt_span))
        npc=min(1.5,max(0.0,(pc-pc_lo)/pc_span))
        # Processor time dominates; weights defined to minimze tiny/narrow jobs
        # from dominating. In the workload, more than 50% of jobs request 1 processor.
        weight=0.05 + 0.65*npt + 0.20*nrt + 0.10*npc
        u=max(rng.random(),1e-15)
        key=-math.log(u)/weight
        keyed.append((key,rng.random(),j))
    keyed.sort(key=lambda x:(x[0],x[1],x[2]["original_job_id"]))
    return [j for _,_,j in keyed]


def select_global_unique_segments(population,seed,main_jobs,window_lengths):
    """Partition one weighted random permutation into main and window segments."""
    if main_jobs<=0 or any(n<=0 for n in window_lengths):
        raise SystemExit("All requested workload sizes must be positive")
    required=main_jobs+sum(window_lengths)
    unique={j["original_job_id"]:j for j in population}
    if required>len(unique):
        raise SystemExit(
            f"Raw workload has {len(unique)} unique valid jobs, but {required} "
            "are required for the principal workload plus all windows"
        )
    permutation=weighted_random_permutation(list(unique.values()),seed)
    main=permutation[:main_jobs]
    windows=[]
    offset=main_jobs
    for n in window_lengths:
        windows.append(permutation[offset:offset+n])
        offset+=n
    used=[j["original_job_id"] for j in main]
    used.extend(j["original_job_id"] for w in windows for j in w)
    if len(used)!=len(set(used)):
        raise RuntimeError("Global no-reuse invariant failed")
    return main,windows,{
        "selection_method":"weighted random permutation without replacement over all valid raw jobs",
        "tiny_job_policy":"all jobs eligible; probability biased toward larger processor-time, runtime and processor count",
        "selection_seed":seed,
        "reserved_main_jobs":main_jobs,
        "window_jobs":sum(window_lengths),
        "total_unique_selected_jobs":len(used),
    }


def choose_main_workload(population,n,seed):
    main,_,meta=select_global_unique_segments(population,seed,n,[])
    return main,meta


def choose_global_unique_windows(population,lengths,seed,reserved_main_ids=None,
                                 reserved_main_jobs=10000,main_selection_seed=2026):
    """Select globally unique windows after excluding the actual main workload."""
    unique={j["original_job_id"]:j for j in population}
    if reserved_main_ids:
        excluded=set(int(x) for x in reserved_main_ids)
        exclusion_source="actual principal workload files"
    else:
        principal=weighted_random_permutation(list(unique.values()),main_selection_seed)
        excluded={j["original_job_id"] for j in principal[:reserved_main_jobs]}
        exclusion_source=(
            f"deterministic principal reservation: jobs={reserved_main_jobs}, "
            f"seed={main_selection_seed}"
        )
    candidates=[j for jid,j in unique.items() if jid not in excluded]
    required=sum(lengths)
    if required>len(candidates):
        raise SystemExit(
            f"After excluding {len(excluded)} principal-workload jobs, only "
            f"{len(candidates)} unique raw jobs remain, but {required} are required"
        )
    permutation=weighted_random_permutation(candidates,seed)
    result=[]; offset=0
    for n in lengths:
        jobs=permutation[offset:offset+n]; offset+=n
        jobs=sorted(jobs,key=lambda j:(j["original_submit_time"],j["original_job_id"]))
        result.append((-1,jobs))
    selected_ids={j["original_job_id"] for _,jobs in result for j in jobs}
    if selected_ids & excluded:
        raise RuntimeError("Principal/window no-reuse invariant failed")
    return result,{
        "selection_method":"weighted random permutation without replacement over all valid raw jobs after excluding the principal workload",
        "tiny_job_policy":"all remaining jobs eligible; probability biased toward larger processor-time, runtime and processor count",
        "selection_seed":seed,
        "principal_exclusion_source":exclusion_source,
        "excluded_principal_jobs":len(excluded),
        "window_jobs":len(selected_ids),
    }

def prepare_volume_levels(jobs,capacity,targets,seed):
    """Create nested exact-count load levels with random heterogeneous composition.

    Load levels contain exact fractions of the maximum job count. A stratified random membership ranking across processor-time deciles prevents
    lower-load subsets from being dominated by only tiny or only very large jobs.
    This ranking is used only to decide membership. Every resulting workload is
    then restored to the original chronological submit order before it is written.
    """
    if not jobs: raise ValueError("jobs must not be empty")
    targets=sorted(set(float(x) for x in targets))
    if not targets or targets[0]<=0: raise ValueError("target loads must be positive")
    if capacity<=0: raise ValueError("platform capacity must be positive")

    ordered=sorted(jobs,key=lambda j:(j["original_submit_time"],j["original_job_id"]))
    first_submit=ordered[0]["original_submit_time"]
    last_submit=ordered[-1]["original_submit_time"]
    original_span=last_submit-first_submit
    if original_span<=0: raise ValueError("selected jobs have a degenerate submission horizon")

    def work(j): return float(j["replay_processors"])*float(j["observed_runtime"])
    total_work=sum(work(j) for j in ordered)
    max_target=max(targets)
    fixed_horizon=total_work/(max_target*capacity)
    if fixed_horizon<=0: raise ValueError("computed fixed horizon is not positive")

    # Preserve the first and last chronological jobs in every level so all
    # levels have exactly the same submission horizon for fair comparison.
    mandatory=[0,len(ordered)-1] if len(ordered)>1 else [0]
    candidate_indices=[i for i in range(len(ordered)) if i not in set(mandatory)]

    # Processor-time deciles preserve the complete heterogeneous distribution.
    strata_count=min(10,max(1,len(candidate_indices)))
    by_work=sorted(candidate_indices,key=lambda i:(work(ordered[i]),ordered[i]["original_job_id"]))
    strata=[]
    for k in range(strata_count):
        lo=(k*len(by_work))//strata_count
        hi=((k+1)*len(by_work))//strata_count
        strata.append(by_work[lo:hi])

    rng=random.Random(seed)
    for stratum in strata:
        rng.shuffle(stratum)

    ranking=[]
    active=[k for k,s in enumerate(strata) if s]
    positions=[0]*len(strata)
    while active:
        round_order=active[:]
        rng.shuffle(round_order)
        next_active=[]
        for k in round_order:
            pos=positions[k]
            if pos<len(strata[k]):
                ranking.append(strata[k][pos])
                positions[k]+=1
            if positions[k]<len(strata[k]):
                next_active.append(k)
        active=next_active

    ranking=mandatory+ranking
    if len(ranking)!=len(ordered) or len(set(ranking))!=len(ordered):
        raise RuntimeError("Exact-count heterogeneous ranking invariant failed")

    levels={}
    previous=set()
    previous_count=0
    for target in targets:
        target_count=int(round(len(ordered)*(target/max_target)))
        target_count=max(len(mandatory),min(len(ordered),target_count))
        target_count=max(previous_count,target_count)
        selected_set=set(ranking[:target_count])
        if not previous.issubset(selected_set):
            raise RuntimeError("Design-B nested-subset invariant failed")
        previous=selected_set
        previous_count=target_count
        selected_jobs=[ordered[i] for i in sorted(selected_set)]
        selected_work=sum(work(j) for j in selected_jobs)
        reservation_work=sum(float(j["replay_processors"])*float(j["requested_walltime"])
                             for j in selected_jobs)
        expected_count_fraction=target/max_target
        levels[target]={
            "jobs":selected_jobs,
            "target_offered_load":target,
            "maximum_target_offered_load":max_target,
            "target_job_count":target_count,
            "expected_job_count_fraction":expected_count_fraction,
            "selected_execution_processor_seconds":selected_work,
            "selected_reservation_processor_seconds":reservation_work,
            "workload_volume_fraction":selected_work/total_work,
            "job_count_fraction":len(selected_jobs)/len(ordered),
            "processor_time_strata":strata_count,
            "selection_method":"exact-count nested stratified-random membership; original chronological arrival order preserved",
        }
    return {
        "levels":levels,
        "fixed_arrival_horizon_seconds":fixed_horizon,
        "original_arrival_horizon_seconds":original_span,
        "original_first_submit":first_submit,
        "full_execution_processor_seconds":total_work,
        "maximum_target_offered_load":max_target,
        "maximum_jobs":len(ordered),
        "selection_seed":seed,
        "processor_time_strata":strata_count,
        "selection_method":"exact-count nested stratified-random membership; original chronological arrival order preserved",
    }


def write_scheduler_csv(path,jobs,capacity,target_load,volume_plan):
    """Write one Design-B workload: fixed horizon, increasing work volume."""
    if target_load<=0: raise ValueError("target load must be positive")
    first=volume_plan["original_first_submit"]
    original_span=volume_plan["original_arrival_horizon_seconds"]
    fixed_horizon=volume_plan["fixed_arrival_horizon_seconds"]
    time_scale=fixed_horizon/original_span
    total_work=sum(j["replay_processors"]*j["observed_runtime"] for j in jobs)
    reservation_work=sum(j["replay_processors"]*j["requested_walltime"] for j in jobs)
    fields=["id","submit_time","observed_runtime","requested_processors","requested_walltime","queue",
            "work_flops","requested_memory_mb","req_platform","original_job_id"]
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open("w",newline="") as f:
        w=csv.writer(f); w.writerow(fields)
        for i,j in enumerate(jobs):
            submit=(j["original_submit_time"]-first)*time_scale
            w.writerow([i,submit,j["observed_runtime"],j["replay_processors"],
                        j["requested_walltime"],j["queue"],f'{j["work_flops"]:.17g}',
                        j["requested_memory_mb"],j["req_platform_raw"],j["original_job_id"]])
    submits=[(j["original_submit_time"]-first)*time_scale for j in jobs]
    achieved_span=max(submits)-min(submits)
    if abs(achieved_span-fixed_horizon)>max(1e-6,1e-9*fixed_horizon):
        raise RuntimeError("Design-B invariant failed: load levels do not share the fixed horizon")
    achieved_execution_load=total_work/(fixed_horizon*capacity)
    achieved_reservation_load=reservation_work/(fixed_horizon*capacity)
    level=volume_plan["levels"][target_load]
    return {"load_design":"B_FIXED_HORIZON_EXACT_JOB_COUNT_RANDOM_HETEROGENEOUS_CHRONOLOGICAL_REPLAY",
            "target_offered_load":target_load,
            "maximum_target_offered_load":volume_plan["maximum_target_offered_load"],
            "achieved_execution_offered_load":achieved_execution_load,
            "achieved_reservation_offered_load":achieved_reservation_load,
            "arrival_horizon_seconds":fixed_horizon,
            "original_arrival_horizon_seconds":original_span,
            "execution_processor_seconds":total_work,
            "reservation_processor_seconds":reservation_work,
            "target_job_count":level["target_job_count"],
            "expected_job_count_fraction":level["expected_job_count_fraction"],
            "workload_volume_fraction":level["workload_volume_fraction"],
            "job_count_fraction":level["job_count_fraction"],
            "processor_time_strata":level["processor_time_strata"],
            "level_selection_method":level["selection_method"],
            "submission_time_scale":time_scale,
            "nested_exact_count_levels":True,
            "original_chronological_order_preserved":True,
            "same_arrival_horizon_across_load_levels":True,
            "platform_capacity_processors":capacity,
            "jobs":len(jobs),"maximum_jobs":volume_plan["maximum_jobs"],
            "sha256":hashlib.sha256(path.read_bytes()).hexdigest()}

def sample_stats(jobs,capacity=None):
    procs=[j["replay_processors"] for j in jobs]; runs=[j["observed_runtime"] for j in jobs]
    out={"jobs":len(jobs),"min_processors":min(procs),"max_processors":max(procs),
         "median_processors":statistics.median(procs),"min_runtime":min(runs),
         "max_runtime":max(runs),"median_runtime":statistics.median(runs),
         "unique_original_jobs":len({j["original_job_id"] for j in jobs})}
    if capacity is not None: out["jobs_above_platform_capacity"]=sum(j["replay_processors"]>capacity for j in jobs)
    return out
PYCOMMON
chmod +x "$BASE_DIR/workload_common.py"

cat > "$BASE_DIR/prepare_real_workload.py" <<'PYFETCH'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, shutil
from workload_common import (ensure_raw, load_or_build_global, choose_main_workload,
                             prepare_volume_levels, write_scheduler_csv, sample_stats,
                             platform_capacity, ROOT)
OUTDIR=ROOT/"cluster_windows"

def parse_loads(text):
    out={}
    for part in text.split(","):
        k,v=part.split("=",1); out[k.strip()]=float(v)
    return out

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--jobs",type=int,default=10000)
    ap.add_argument("--seed",type=int,default=2026)
    ap.add_argument("--high-demand-quantile",type=float,default=0.80)
    ap.add_argument("--force-global",action="store_true")
    ap.add_argument("--raw-file",default=os.environ.get("RAW_WORKLOAD_FILE"))
    ap.add_argument("--loads",default=os.environ.get("SCENARIO_LOADS_OVERRIDE","low=0.40,medium=0.70,high=1.00"))
    a=ap.parse_args()
    raw=ensure_raw(a.raw_file)
    global_jobs,global_meta=load_or_build_global(raw,a.high_demand_quantile,a.force_global)
    jobs,selection_meta=choose_main_workload(global_jobs,a.jobs,a.seed)
    start=-1
    capacity=platform_capacity()
    if len({j["original_job_id"] for j in jobs})!=len(jobs): raise SystemExit("Duplicate original job IDs in main workload")
    OUTDIR.mkdir(parents=True,exist_ok=True)
    for old in OUTDIR.glob("*"):
        if old.is_file(): old.unlink()
    manifest={"selection_seed":a.seed,"global_raw_population_definition":global_meta,
              "selection_method":selection_meta["selection_method"],
              "tiny_job_policy":selection_meta["tiny_job_policy"],
              "global_start_index":start,"same_jobs_across_load_levels":False,
              "nested_jobs_across_load_levels":True,
              "load_design":"B_FIXED_HORIZON_EXACT_JOB_COUNT_RANDOM_HETEROGENEOUS_CHRONOLOGICAL_REPLAY",
              "sample":sample_stats(jobs,capacity),"scenarios":{}}
    scenario_loads=parse_loads(a.loads)
    volume_plan=prepare_volume_levels(jobs,capacity,scenario_loads.values(),a.seed)
    for name,target in scenario_loads.items():
        level_jobs=volume_plan["levels"][target]["jobs"]
        path=OUTDIR/f"{name}.csv"
        meta=write_scheduler_csv(path,level_jobs,capacity,target,volume_plan)
        manifest["scenarios"][name]=meta
        (OUTDIR/f"{name}.metadata.json").write_text(json.dumps({**sample_stats(level_jobs,capacity),**meta,"seed":a.seed,"global_start_index":start},indent=2,sort_keys=True)+"\n")
    (OUTDIR/"selection_manifest.json").write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
    shutil.copyfile(OUTDIR/"high.csv",ROOT/"current_oar_workload.csv")
    print(f"[workload] globally unique weighted-random principal workload: jobs={len(jobs)} source={ROOT/'all_valid_jobs_global.csv'}")
if __name__=="__main__": main()
PYFETCH
chmod +x "$BASE_DIR/prepare_real_workload.py"

cat > "$BASE_DIR/prepare_real_workload.sh" <<'PREP'
#!/bin/bash
set -euo pipefail
JOBS=${1:-10000}
SEED=${2:-2026}
ARGS=(--jobs "$JOBS" --seed "$SEED")
if [ -n "${RAW_WORKLOAD_FILE:-}" ]; then ARGS+=(--raw-file "$RAW_WORKLOAD_FILE"); fi
python3 ./prepare_real_workload.py "${ARGS[@]}"
PREP
chmod +x "$BASE_DIR/prepare_real_workload.sh"

cat > "$BASE_DIR/run_all.sh" <<'RUN'
#!/bin/bash
set -euo pipefail
JOBS=${1:-10000}
SCENARIOS_RAW=${SCENARIOS_OVERRIDE:-"low medium high"}
POLICIES_RAW=${POLICIES_OVERRIDE:-"fifo fifo_matching easy_backfilling conservative_backfilling"}
read -r -a SCENARIOS <<< "$SCENARIOS_RAW"
read -r -a POLICIES <<< "$POLICIES_RAW"

mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
cd ..

rm -f results.csv schedule_trace.csv scenario_results.csv energy_summary.csv rejected_jobs.csv scheduler_diagnostics.csv makespan_tail_jobs.csv

for scenario in "${SCENARIOS[@]}"; do
  CSV="data/real_workloads/cluster_windows/${scenario}.csv"
  if [ ! -s "$CSV" ]; then
    echo "ERROR: missing prepared scenario $CSV" >&2
    echo "Run once: ./prepare_real_workload.sh $JOBS" >&2
    exit 2
  fi

  BEFORE=0
  if [ -s results.csv ]; then
    BEFORE=$(($(wc -l < results.csv)-1))
  fi

  for policy in "${POLICIES[@]}"; do
    echo "Running scenario=$scenario policy=$policy jobs=$JOBS"
    ./build/oar_hpc_energy "$policy" 42 "$JOBS" "$CSV" general "$scenario"
  done

  python3 - "$scenario" "$BEFORE" <<'PY'
import csv, pathlib, sys
scenario=sys.argv[1]
before=int(sys.argv[2])
src=pathlib.Path("results.csv")
dst=pathlib.Path("scenario_results.csv")
rows=list(csv.DictReader(src.open(newline="")))
new_rows=rows[before:]
if not new_rows:
    raise SystemExit(f"No new results found for scenario {scenario}")

fields=["scenario"]+list(new_rows[0].keys())
write_header=not dst.exists() or dst.stat().st_size==0
with dst.open("a",newline="") as f:
    w=csv.DictWriter(f,fieldnames=fields)
    if write_header:
        w.writeheader()
    for row in new_rows:
        clean={k:v for k,v in row.items() if k not in ("scenario","scenario.1")}
        clean["scenario"]=scenario
        w.writerow(clean)
PY
done

echo "Done: results.csv, scenario_results.csv, schedule_trace.csv, rejected_jobs.csv, scheduler_diagnostics.csv, makespan_tail_jobs.csv"
RUN
chmod +x "$BASE_DIR/run_all.sh"

chmod +x "$BASE_DIR/run_all.sh"


cat > "$BASE_DIR/prepare_replicate_windows.py" <<'PYREPS'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, csv, json, os, shutil
from workload_common import (ensure_raw, load_or_build_global, choose_global_unique_windows,
                             prepare_volume_levels, write_scheduler_csv, sample_stats,
                             platform_capacity, ROOT)
OUTDIR=ROOT/"replicate_windows"

def principal_job_ids():
    """Read the actual prepared principal workload and return original IDs."""
    candidates=[ROOT/"cluster_windows/high.csv", ROOT/"current_oar_workload.csv"]
    for path in candidates:
        if path.is_file():
            rows=list(csv.DictReader(path.open(newline="")))
            ids={int(r["original_job_id"]) for r in rows if r.get("original_job_id")}
            if ids:
                return ids,path
    return set(),None

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--jobs-per-window",type=int,default=10000)
    ap.add_argument("--replicates",type=int,default=30)
    ap.add_argument("--seed",type=int,default=2026)
    ap.add_argument("--target-loads",default="0.20,0.40,0.60,0.80,1.00")
    ap.add_argument("--high-demand-quantile",type=float,default=0.80)
    ap.add_argument("--reserved-main-jobs",type=int,default=int(os.environ.get("MAIN_WORKLOAD_JOBS","10000")),
                    help="fallback principal workload size when no prepared principal workload exists")
    ap.add_argument("--main-selection-seed",type=int,default=int(os.environ.get("MAIN_WORKLOAD_SEED","2026")),
                    help="fallback seed used to reserve principal jobs when its workload file is absent")
    ap.add_argument("--force-global",action="store_true")
    ap.add_argument("--raw-file",default=os.environ.get("RAW_WORKLOAD_FILE"))
    a=ap.parse_args()
    targets=[float(x) for x in a.target_loads.split(",") if x.strip()]
    raw=ensure_raw(a.raw_file)
    global_jobs,global_meta=load_or_build_global(raw,a.high_demand_quantile,a.force_global)
    actual_main_ids,main_path=principal_job_ids()
    windows,selection_meta=choose_global_unique_windows(
        global_jobs,[a.jobs_per_window]*a.replicates,a.seed,
        reserved_main_ids=actual_main_ids,
        reserved_main_jobs=a.reserved_main_jobs,
        main_selection_seed=a.main_selection_seed,
    )
    if main_path:
        print(f"[replicates] excluding {len(actual_main_ids)} jobs from principal workload: {main_path}")
    else:
        print("[replicates] principal workload not found; using deterministic fallback reservation")
    capacity=platform_capacity()
    if OUTDIR.exists(): shutil.rmtree(OUTDIR)
    OUTDIR.mkdir(parents=True)
    manifest=[]
    for r,(start,jobs) in enumerate(windows,1):
        ids={j["original_job_id"] for j in jobs}
        if len(ids)!=len(jobs): raise RuntimeError("Duplicate original job IDs inside one window")
        repdir=OUTDIR/f"window_{r:02d}"; repdir.mkdir()
        volume_plan=prepare_volume_levels(jobs,capacity,targets,a.seed+r)
        for target in sorted(targets):
            level_jobs=volume_plan["levels"][target]["jobs"]
            tag=f"load_{target:.2f}".replace(".","p")
            path=repdir/f"{tag}.csv"
            meta=write_scheduler_csv(path,level_jobs,capacity,target,volume_plan)
            full={"window_id":r,"global_seed":a.seed,"global_start_index":start,
                  "selection_method":selection_meta["selection_method"],
                  "tiny_job_policy":selection_meta["tiny_job_policy"],
                  "reserved_main_jobs":selection_meta["excluded_principal_jobs"],
                  "principal_exclusion_source":selection_meta["principal_exclusion_source"],
                  "load_design":"B_FIXED_HORIZON_EXACT_JOB_COUNT_RANDOM_HETEROGENEOUS_CHRONOLOGICAL_REPLAY",
                  **sample_stats(level_jobs,capacity),**meta,
                  "workload_file":str(path)}
            (repdir/f"{tag}.metadata.json").write_text(json.dumps(full,indent=2,sort_keys=True)+"\n")
            manifest.append(full)
        print(f"[replicates] window={r:02d} jobs={len(jobs)}")
    with (OUTDIR/"experiment_manifest.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(manifest[0])); w.writeheader(); w.writerows(manifest)
    print(f"[replicates] created {a.replicates} globally unique weighted-random windows")
    print(f"[replicates] excluded principal jobs={selection_meta['excluded_principal_jobs']}; unique window jobs={a.jobs_per_window*a.replicates}")
if __name__=="__main__": main()
PYREPS
chmod +x "$BASE_DIR/prepare_replicate_windows.py"

cat > "$BASE_DIR/prepare_replicate_windows.sh" <<'REPSH'
#!/bin/bash
set -euo pipefail
JOBS=${1:-10000}
REPLICATES=${2:-30}
SEED=${3:-2026}
TARGET_LOADS=${TARGET_LOADS_OVERRIDE:-"0.20,0.40,0.60,0.80,1.00"}
ARGS=(--jobs-per-window "$JOBS" --replicates "$REPLICATES" --seed "$SEED" --target-loads "$TARGET_LOADS")
if [ -n "${RAW_WORKLOAD_FILE:-}" ]; then ARGS+=(--raw-file "$RAW_WORKLOAD_FILE"); fi
if [ -n "${MAIN_WORKLOAD_JOBS:-}" ]; then ARGS+=(--reserved-main-jobs "$MAIN_WORKLOAD_JOBS"); fi
if [ -n "${MAIN_WORKLOAD_SEED:-}" ]; then ARGS+=(--main-selection-seed "$MAIN_WORKLOAD_SEED"); fi
python3 ./prepare_replicate_windows.py "${ARGS[@]}"
REPSH
chmod +x "$BASE_DIR/prepare_replicate_windows.sh"

cat > "$BASE_DIR/run_raw_experiments.sh" <<'RAWEXP'
#!/bin/bash
set -euo pipefail
JOBS=${1:-2000}
REPLICATES=${2:-10}
POLICIES_RAW=${POLICIES_OVERRIDE:-"fifo fifo_matching easy_backfilling conservative_backfilling"}
TIMEOUT_SECONDS=${SCHEDULER_TIMEOUT_SECONDS:-7200}
RESUME=${RESUME_EXPERIMENTS:-1}
read -r -a POLICIES <<< "$POLICIES_RAW"
INPUT_ROOT="data/real_workloads/replicate_windows"
OUTPUT_ROOT="raw_experiments"
MANIFEST="$INPUT_ROOT/experiment_manifest.csv"
if [ ! -s "$MANIFEST" ]; then
  echo "ERROR: missing $MANIFEST" >&2
  echo "Run: ./prepare_replicate_windows.sh $JOBS $REPLICATES" >&2
  exit 2
fi
mkdir -p build
(cd build && cmake .. -DCMAKE_BUILD_TYPE=Release && make -j"$(nproc)")
if [ "$RESUME" != "1" ]; then rm -rf "$OUTPUT_ROOT"; fi
mkdir -p "$OUTPUT_ROOT"
cp "$MANIFEST" "$OUTPUT_ROOT/experiment_manifest.csv"
python3 - "$MANIFEST" "$REPLICATES" <<'PYLIST' > "$OUTPUT_ROOT/run_list.tsv"
import csv,sys
manifest=sys.argv[1]; max_rep=int(sys.argv[2])
for r in csv.DictReader(open(manifest,newline="")):
    if int(r["window_id"])<=max_rep:
        tag=f"load_{float(r['target_offered_load']):.2f}".replace(".","p")
        print(f"{int(r['window_id']):02d}\t{tag}\t{r['workload_file']}")
PYLIST
while IFS=$'\t' read -r window load_tag csv_path; do
  [ -n "$window" ] || continue
  outdir="$OUTPUT_ROOT/window_${window}/${load_tag}"
  mkdir -p "$outdir"
  if [ "$RESUME" = "1" ] && [ -s "$outdir/results.csv" ]; then
    rows=$(($(wc -l < "$outdir/results.csv")-1))
    if [ "$rows" -eq "${#POLICIES[@]}" ]; then
      echo "Skipping completed window=$window load=$load_tag"
      continue
    fi
  fi
  rm -f results.csv schedule_trace.csv scenario_results.csv energy_summary.csv rejected_jobs.csv scheduler_diagnostics.csv makespan_tail_jobs.csv
  : > "$outdir/run_status.tsv"
  for policy in "${POLICIES[@]}"; do
    echo "Running window=$window load=$load_tag policy=$policy jobs=$JOBS timeout=${TIMEOUT_SECONDS}s"
    start_epoch=$(date +%s)
    set +e
    timeout --signal=TERM --kill-after=60s "${TIMEOUT_SECONDS}s" \
      ./build/oar_hpc_energy "$policy" 42 "$JOBS" "$csv_path" window "$window" "$load_tag" \
      > >(tee "$outdir/${policy}.stdout.log") \
      2> >(tee "$outdir/${policy}.stderr.log" >&2)
    rc=$?
    set -e
    elapsed=$(( $(date +%s)-start_epoch ))
    printf '%s\t%s\t%s\t%s\n' "$policy" "$rc" "$elapsed" "$(date -Is)" >> "$outdir/run_status.tsv"
    if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
      echo "ERROR: policy=$policy timed out after ${TIMEOUT_SECONDS}s at window=$window load=$load_tag" >&2
      echo "Inspect $outdir/${policy}.stderr.log and rerun with a larger SCHEDULER_TIMEOUT_SECONDS if justified." >&2
      exit 124
    elif [ "$rc" -ne 0 ]; then
      echo "ERROR: policy=$policy failed with exit code $rc" >&2
      exit "$rc"
    fi
  done
  python3 - "$window" "$load_tag" <<'PYLOAD'
import csv,pathlib,sys
window=sys.argv[1]; load=sys.argv[2]
src=pathlib.Path("results.csv"); dst=pathlib.Path("scenario_results.csv")
rows=list(csv.DictReader(src.open(newline="")))
if not rows: raise SystemExit("No raw result rows produced")
fields=["window","load"]+list(rows[0].keys())
with dst.open("w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
    for row in rows:
        clean={k:v for k,v in row.items() if k not in ("window","load","scenario","scenario.1")}
        clean["window"]=window; clean["load"]=load; w.writerow(clean)
PYLOAD
  cp results.csv "$outdir/results.csv"
  cp scenario_results.csv "$outdir/scenario_results.csv"
  cp schedule_trace.csv "$outdir/schedule_trace.csv"
  cp scheduler_diagnostics.csv "$outdir/scheduler_diagnostics.csv"
  cp makespan_tail_jobs.csv "$outdir/makespan_tail_jobs.csv"
  cp energy_summary.csv "$outdir/energy_summary.csv"
  [ ! -s rejected_jobs.csv ] || cp rejected_jobs.csv "$outdir/rejected_jobs.csv"
  cp "$csv_path" "$outdir/input_workload.csv"
  meta="${csv_path%.csv}.metadata.json"
  [ ! -s "$meta" ] || cp "$meta" "$outdir/input_workload.metadata.json"
done < "$OUTPUT_ROOT/run_list.tsv"
rm -f results.csv schedule_trace.csv scenario_results.csv energy_summary.csv rejected_jobs.csv scheduler_diagnostics.csv makespan_tail_jobs.csv
echo "Done. Raw files are under $OUTPUT_ROOT/window_XX/load_XpXX/"
RAWEXP
chmod +x "$BASE_DIR/run_raw_experiments.sh"

cat > "$BASE_DIR/tests/deterministic_workload.csv" <<'CSV'
id,submit_time,observed_runtime,requested_processors,requested_walltime,queue
0,0,120,32,300,normal
1,10,30,4,120,normal
2,20,600,128,1200,normal
CSV

cat > "$BASE_DIR/summarize_results.py" <<'PY'
#!/usr/bin/env python3
import csv, statistics as st, sys
from collections import defaultdict
path = sys.argv[1] if len(sys.argv) > 1 else 'results.csv'
metrics = ['makespan','total_energy','avg_wait','avg_turnaround','avg_slowdown','bounded_slowdown_tau10','bounded_slowdown_tau60','utilization','energy_per_job','deadline_misses','walltime_violations','backfilled_jobs','fairness']
rows=[]
with open(path, newline='') as f:
    rows=list(csv.DictReader(f))
by=defaultdict(list)
for r in rows:
    by[r['scheduler']].append(r)
print('scheduler,runs,' + ','.join(m + '_mean,' + m + '_median,' + m + '_std' for m in metrics))
for sched in sorted(by):
    out=[sched, str(len(by[sched]))]
    for m in metrics:
        x=[float(r[m]) for r in by[sched]]
        out.extend([f'{sum(x)/len(x):.6g}', f'{st.median(x):.6g}', f'{(st.stdev(x) if len(x)>1 else 0.0):.6g}'])
    print(','.join(out))
PY
chmod +x "$BASE_DIR/summarize_results.py"

cat > "$BASE_DIR/swf_to_oar_csv.py" <<'PYSWF'
#!/usr/bin/env python3
"""Convert Standard Workload Format (SWF) traces to this simulator CSV.
SWF fields used: job_id, submit_time, run_time, allocated_processors,
requested_processors, requested_time, requested_memory. Unknown values (-1)
are replaced conservatively. Output columns match the simulator input.
"""
import sys, math, random
if len(sys.argv) < 3:
    print('usage: swf_to_oar_csv.py input.swf output.csv [max_jobs]', file=sys.stderr)
    sys.exit(2)
inp, out = sys.argv[1], sys.argv[2]
max_jobs = int(sys.argv[3]) if len(sys.argv) > 3 else None
random.seed(42)
written = 0
with open(inp) as f, open(out, 'w') as g:
    g.write('id,submit_time,flops,io_bytes,requested_nodes,cores_per_node,memory_per_node_gb,walltime,deadline,req_arch\n')
    for line in f:
        line=line.strip()
        if not line or line.startswith(';') or line.startswith('#'): continue
        parts=line.split()
        if len(parts) < 9: continue
        jid=int(parts[0]); submit=max(0.0,float(parts[1])); runtime=max(1.0,float(parts[3]))
        alloc=int(float(parts[4])) if float(parts[4]) > 0 else 1
        req_procs=int(float(parts[7])) if float(parts[7]) > 0 else alloc
        req_time=float(parts[8]) if float(parts[8]) > 0 else runtime*2.0
        req_mem=float(parts[9]) if len(parts)>9 and float(parts[9]) > 0 else 32.0
        nodes=max(1, math.ceil(req_procs/16))
        cores=max(1, min(32, math.ceil(req_procs/nodes)))
        mem_gb=max(4.0, min(192.0, req_mem/1024.0 if req_mem > 512 else req_mem))
        wall=max(runtime, req_time)
        deadline=submit + runtime*random.uniform(15.0,60.0)
        flops=runtime*2.5e9*nodes
        io=max(1e6, runtime*random.uniform(1e7,8e8))
        arch='any'
        g.write(f'{written},{submit},{flops:.6g},{io:.6g},{nodes},{cores},{mem_gb:.6g},{wall:.6g},{deadline:.6g},{arch}\n')
        written += 1
        if max_jobs and written >= max_jobs: break
print(f'Wrote {written} jobs to {out}')
PYSWF
chmod +x "$BASE_DIR/swf_to_oar_csv.py"

cat > "$BASE_DIR/validate_platform.py" <<'PYPLAT'
#!/usr/bin/env python3
import csv, collections, sys
p="platforms/grid5000_like_inventory.csv"
rows=list(csv.DictReader(open(p)))
errors=[]
arches=collections.Counter(r["cpuarch"] for r in rows)
for required in ("x86_64","aarch64","ppc64le"):
    if arches[required] == 0: errors.append(f"missing architecture {required}")
for r in rows:
    for k in ("site","cluster","cpuarch","core_count","memnode_mb","cpufreq_ghz","disktype","eth_rate_gbps","gpu_count"):
        if r.get(k,"")=="": errors.append(f"{r['node_id']}: missing {k}")
print("nodes:",len(rows))
print("architectures:",dict(arches))
print("GPU nodes:",sum(int(r["gpu_count"])>0 for r in rows))
print("NVMe/SSD nodes:",sum("SSD" in r["disktype"] for r in rows))
if errors:
    print("PLATFORM VALIDATION FAILED")
    print("\n".join(errors[:30])); sys.exit(1)
print("PLATFORM VALIDATION PASS")
PYPLAT
chmod +x "$BASE_DIR/validate_platform.py"

cat > "$BASE_DIR/README.md" <<'MD'
# OAR-SimGrid HPC Scheduling Simulator

Trace-driven simulator for comparing four scheduling policies on a heterogeneous
Grid'5000-inspired platform modeled with SimGrid:

1. FIFO
2. FIFO with Matching
3. EASY Backfilling
4. Conservative Backfilling

All policies share the same workload, resource model, execution model and energy
model. FIFO with Matching changes resource placement while preserving FIFO queue
order; EASY protects the queue-head reservation; Conservative protects reservations
for all waiting jobs.

## Requirements

- C++17 compiler
- CMake
- pkg-config
- SimGrid
- Python 3

## Main workflow

```bash
./prepare_real_workload.sh 10000
./run_all.sh 10000
```

For replicate-window experiments:

```bash
./prepare_replicate_windows.sh 10000 30 42 --arguments: number-of-jobs number-of-windows seed 
./validate_experiment_inputs.py --expected-windows 30 --jobs-per-window 10000
./run_raw_experiments.sh 10000 30
```

## Main outputs

- `results.csv`
- `scenario_results.csv`
- `schedule_trace.csv`
- `energy_summary.csv`
- `scheduler_diagnostics.csv`
- `makespan_tail_jobs.csv`
- `rejected_jobs.csv` when admission rejections occur

The platform definition is stored in `platforms/grid5000_like_64nodes.xml`, and
its generated inventory is stored in `platforms/grid5000_like_inventory.csv`.
MD
cat > "$BASE_DIR/validate_trace.py" <<'PYVAL'
#!/usr/bin/env python3
import csv, sys, math
from collections import defaultdict
path = sys.argv[1] if len(sys.argv) > 1 else 'schedule_trace.csv'
rows = list(csv.DictReader(open(path, newline='')))
errors = []
by = defaultdict(list)
for r in rows:
    by[(r['scheduler'], r['seed'])].append(r)
    s = float(r['start']); e = float(r['end']); sub = float(r.get('submit_time', 0)); wt = float(r.get('walltime', 1e100))
    if s + 1e-9 < sub:
        errors.append(f"job {r['job_id']} in {r['scheduler']}/seed {r['seed']} starts before submit")
    if e + 1e-9 < s:
        errors.append(f"job {r['job_id']} in {r['scheduler']}/seed {r['seed']} ends before start")
    if e - s > wt + 1e-6:
        errors.append(f"job {r['job_id']} in {r['scheduler']}/seed {r['seed']} exceeds declared walltime in trace")
    if r['scheduler'] in ('FIFO','FIFO_with_Matching') and r['decision'] not in ('HEAD','REJECTED'):
        errors.append(f"{r['scheduler']} used invalid decision {r['decision']} for job {r['job_id']}")
    if r['decision'] == 'HEAD' and r['backfilled'] != '0':
        errors.append(f"HEAD decision marked as backfilled for job {r['job_id']}")
    if 'BACKFILL' in r['decision'] and r['backfilled'] != '1':
        errors.append(f"backfill decision not marked as backfilled for job {r['job_id']}")

# FIFO-style no-bypass check
for key, rs in by.items():
    sched, seed = key
    if sched in ('FIFO','FIFO_with_Matching'):
        active = [r for r in rs if r['decision'] != 'REJECTED']
        ordered = sorted(active, key=lambda r: (float(r['start']), int(r['job_id'])))
        max_seen = -1
        for r in ordered:
            jid = int(r['job_id'])
            if jid < max_seen:
                errors.append(f"{sched}/seed {seed} violates FIFO order around job {jid}")
                break
            max_seen = max(max_seen, jid)

if errors:
    print('TRACE VALIDATION FAILED')
    for e in errors[:50]: print(' -', e)
    print(f'Total errors: {len(errors)}')
    sys.exit(1)
print(f'TRACE VALIDATION PASSED: {len(rows)} decisions checked across {len(by)} scheduler/seed groups')
PYVAL
chmod +x "$BASE_DIR/validate_trace.py"


cat > "$BASE_DIR/validate_accounting.py" <<'PYACC'
#!/usr/bin/env python3
import csv, sys
path = sys.argv[1] if len(sys.argv) > 1 else 'results.csv'
rows = list(csv.DictReader(open(path, newline='')))
errors = []
for r in rows:
    submitted = int(float(r['submitted_jobs']))
    completed = int(float(r['completed_jobs']))
    rejected = int(float(r['rejected_jobs']))
    pending = int(float(r['pending_jobs']))
    killed = int(float(r['walltime_violations']))
    if submitted != completed + killed + rejected + pending:
        errors.append(f"{r['scheduler']}/seed {r['seed']}: submitted != completed + walltime_killed + rejected + pending")
    if pending != 0:
        errors.append(f"{r['scheduler']}/seed {r['seed']}: pending_jobs={pending}")
if errors:
    print('ACCOUNTING VALIDATION FAILED')
    for e in errors[:50]: print(' -', e)
    print(f'Total errors: {len(errors)}')
    sys.exit(1)
print(f'ACCOUNTING VALIDATION PASSED: {len(rows)} rows checked')
PYACC
chmod +x "$BASE_DIR/validate_accounting.py"

cat > "$BASE_DIR/EXPERIMENTAL_PROTOCOL.md" <<'MDPROTO'
# Experimental Protocol

## Scheduling policies

- **FIFO:** strict head-of-line dispatch with first-feasible placement.
- **FIFO with Matching:** strict FIFO order with non-clairvoyant placement based
  on feasible resource sets, locality, processing capacity and network capability.
- **EASY Backfilling:** protects the reservation of the first waiting job.
- **Conservative Backfilling:** protects a reservation for every waiting job.

Reservations and backfilling decisions use requested walltime. Observed runtime is
not used to authorize future scheduling decisions.

## Workload design

Replicate windows are sampled without replacement from valid GWA-T-2 records.
Windows are mutually disjoint. Load levels are nested subsets containing 20%, 40%,
60%, 80% and 100% of each maximum workload, with a common normalized submission
horizon and chronological replay of the selected jobs.

## Reproducibility checks

```bash
./validate_platform.py
./validate_experiment_inputs.py --expected-windows 30 --jobs-per-window 10000
./validate_accounting.py
./validate_trace.py
```
MDPROTO
cat > "$BASE_DIR/MODELING_ASSUMPTIONS.md" <<'MDASSUME'
# Modeling Assumptions and Provenance

| Model field | Treatment | Provenance |
|---|---|---|
| Submit time | Taken from the trace and normalized within each prepared workload | SWF field 2 |
| Observed runtime | Used to derive simulated compute work | SWF field 4 |
| Processors | Replayed from the selected SWF processor field according to `PROCESSOR_REPLAY_MODE` | SWF processor fields |
| Walltime | Requested Time; records without a valid value are excluded | SWF field 9 |
| Requested memory | Requested memory when available; otherwise used-memory fallback or no memory constraint | SWF fields 7 and 10 |
| CPU architecture | Controlled experimental property when assigned; not an original SWF field | Platform model |
| Energy | SimGrid Host Energy plugin with one CPU pstate per selected host | SimGrid |
| Scheduling | FIFO, FIFO with Matching, EASY Backfilling and Conservative Backfilling | OAR-inspired model |

## Scope

The platform is a heterogeneous Grid'5000-inspired model. 
The workload trace does not provide application communication graphs,
message sizes or per-job network traffic; therefore the simulator does not model MPI
communication or application-generated network contention.

## Primary sources

- Parallel Workloads Archive, Standard Workload Format:
  https://www.cs.huji.ac.il/labs/parallel/workload/swf.html
- GWA-T-2:
  https://atlarge-research.com/gwa-t-2/
- Grid'5000 hardware:
  https://www.grid5000.fr/w/Hardware
- OAR:
  https://oar.imag.fr/
- SimGrid plugins:
  https://simgrid.org/doc/latest/Plugins.html
MDASSUME
echo "Created $BASE_DIR"

echo "Next steps:"
echo "  cd $BASE_DIR"
echo "  ./validate_platform.py"
echo "  ./prepare_real_workload.sh 10000   # execute once; cached trace is reused"
echo "  ./run_all.sh 10000"
echo "  RAW_WORKLOAD_FILE=/path/to/gwa_t_2_anon_jobs_gwf.zip ./prepare_replicate_windows.sh 10000 30"
echo "  ./run_raw_experiments.sh 10000 30"
echo "  ./validate_accounting.py"
echo "  ./validate_trace.py"
echo "  ./summarize_results.py > summary_stats.csv"


cat > "$BASE_DIR/validate_experiment_inputs.py" <<'PYVALID'
#!/usr/bin/env python3
from __future__ import annotations
import argparse, csv, hashlib, math, pathlib, statistics, sys

ROOT=pathlib.Path("data/real_workloads")

def read_csv(path):
    rows=list(csv.DictReader(path.open(newline="")))
    if not rows: raise RuntimeError(f"Empty workload: {path}")
    return rows

def summarize(path):
    rows=read_csv(path)
    ids=[int(r["original_job_id"]) for r in rows]
    submit=[float(r["submit_time"]) for r in rows]
    proc=[int(r["requested_processors"]) for r in rows]
    run=[float(r["observed_runtime"]) for r in rows]
    if len(ids)!=len(set(ids)): raise RuntimeError(f"Duplicate jobs inside {path}")
    if submit!=sorted(submit): raise RuntimeError(f"Submission order is not chronological: {path}")
    if min(submit)<-1e-9: raise RuntimeError(f"Negative submission time: {path}")
    if len(set(submit))<2: raise RuntimeError(f"Degenerate submission times: {path}")
    if min(proc)<1 or min(run)<=0: raise RuntimeError(f"Invalid job resources/runtime: {path}")
    span=max(submit)-min(submit)
    volume=sum(p*r for p,r in zip(proc,run))
    return {"rows":rows,"ids":set(ids),"id_order":ids,"jobs":len(rows),
            "arrival_horizon_seconds":span,"execution_processor_seconds":volume,
            "proc_min":min(proc),"proc_median":statistics.median(proc),"proc_max":max(proc),
            "runtime_median":statistics.median(run),"runtime_max":max(run),
            "sha256":hashlib.sha256(path.read_bytes()).hexdigest()}

def load_value(path):
    return float(path.stem.split("load_",1)[1].replace("p","."))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--expected-windows",type=int,default=30)
    ap.add_argument("--jobs-per-window",type=int,default=10000,
                    help="maximum job count, expected at the highest load")
    a=ap.parse_args()
    manifest=ROOT/"replicate_windows/experiment_manifest.csv"
    if not manifest.is_file(): raise SystemExit(f"Missing {manifest}")
    windows=sorted((ROOT/"replicate_windows").glob("window_*"))
    if len(windows)!=a.expected_windows:
        raise SystemExit(f"Expected {a.expected_windows} windows, found {len(windows)}")
    all_max_ids=set(); max_window_use={}; report=[]
    principal_ids=set()
    principal=ROOT/"cluster_windows/high.csv"
    if principal.is_file():
        principal_ids=summarize(principal)["ids"]
    for wd in windows:
        files=sorted(wd.glob("load_*.csv"),key=load_value)
        if not files: raise RuntimeError(f"No load files in {wd}")
        summaries=[(load_value(p),p,summarize(p)) for p in files]
        horizons=[x[2]["arrival_horizon_seconds"] for x in summaries]
        ref=horizons[0]
        tol=max(1e-6,1e-9*max(1.0,ref))
        if any(abs(h-ref)>tol for h in horizons[1:]):
            raise RuntimeError(f"{wd}: Design-B fixed-horizon invariant failed: {horizons}")
        previous_ids=set(); previous_jobs=0; previous_volume=-1.0
        max_load_value=summaries[-1][0]
        for load,p,x in summaries:
            expected_jobs=int(round(a.jobs_per_window*(load/max_load_value)))
            expected_jobs=max(2,min(a.jobs_per_window,expected_jobs))
            if x["jobs"]!=expected_jobs:
                raise RuntimeError(
                    f"{wd}: load {load:.2f} must contain exactly {expected_jobs} jobs; "
                    f"found {x['jobs']}"
                )
            if not previous_ids.issubset(x["ids"]):
                raise RuntimeError(f"{wd}: load {load:.2f} is not a nested superset of the previous level")
            if x["jobs"]<previous_jobs:
                raise RuntimeError(f"{wd}: job count decreases at load {load:.2f}")
            if x["execution_processor_seconds"]+1e-9<previous_volume:
                raise RuntimeError(f"{wd}: workload volume decreases at load {load:.2f}")
            previous_ids=x["ids"]; previous_jobs=x["jobs"]; previous_volume=x["execution_processor_seconds"]
        max_load,max_path,max_summary=summaries[-1]
        if max_summary["jobs"]!=a.jobs_per_window:
            raise RuntimeError(f"{wd}: highest load must contain {a.jobs_per_window} jobs; found {max_summary['jobs']}")
        principal_overlap=principal_ids & max_summary["ids"]
        if principal_overlap:
            raise RuntimeError(
                f"{wd}: {len(principal_overlap)} jobs overlap the principal workload; "
                f"examples={sorted(principal_overlap)[:10]}"
            )
        overlap=all_max_ids & max_summary["ids"]
        for job_id in max_summary["ids"]:
            max_window_use[job_id]=max_window_use.get(job_id,0)+1
        all_max_ids |= max_summary["ids"]
        report.append({"window":wd.name,"load_design":"B_FIXED_HORIZON_EXACT_JOB_COUNT_RANDOM_HETEROGENEOUS_CHRONOLOGICAL_REPLAY",
                       "fixed_arrival_horizon_seconds":ref,
                       "minimum_load":summaries[0][0],"maximum_load":max_load,
                       "minimum_jobs":summaries[0][2]["jobs"],"maximum_jobs":max_summary["jobs"],
                       "minimum_execution_processor_seconds":summaries[0][2]["execution_processor_seconds"],
                       "maximum_execution_processor_seconds":max_summary["execution_processor_seconds"],
                       "cross_window_maximum_load_overlap":len(overlap),
                       "principal_workload_overlap":len(principal_overlap)})
    out=ROOT/"replicate_windows/workload_validation_report.csv"
    with out.open("w",newline="") as f:
        fields=list(report[0]); w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(report)
    reuse_counts=list(max_window_use.values())
    repeated=[job_id for job_id,count in max_window_use.items() if count>1]
    if repeated:
        raise RuntimeError(
            f"Cross-window job reuse detected for {len(repeated)} original jobs; "
            f"examples={repeated[:10]}"
        )
    expected_unique=a.expected_windows*a.jobs_per_window
    if len(all_max_ids)!=expected_unique:
        raise RuntimeError(
            f"Expected {expected_unique} distinct maximum-volume jobs, found {len(all_max_ids)}"
        )
    print(f"VALIDATION PASS: Design B exact-count, principal workload and {len(windows)} windows are globally unique; fixed horizons and nested heterogeneous random levels")
    print(f"Distinct maximum-volume source jobs: {len(all_max_ids)}; cross-window reuse=0; report: {out}")

if __name__=="__main__":
    try: main()
    except Exception as e:
        print(f"VALIDATION FAILED: {e}",file=sys.stderr); raise
PYVALID
chmod +x "$BASE_DIR/validate_experiment_inputs.py"


echo "Project generated in $BASE_DIR"
