# Lab 3 - Part III: 8x8 Systolic Matrix Multiplier



## Overview



This project implements an 8x8 FP8 systolic matrix multiplier using four interconnected 4x4 systolic matrix multiplier blocks.



The original `MAT_MUL_SIZE` remains 4. The larger 8x8 architecture is created by instantiating four `matmul_4x4_systolic` modules and connecting the systolic A and B data paths between neighboring blocks.



SystemVerilog syntax is used throughout the Part III design.



---



## 8x8 Microarchitecture



The four 4x4 blocks are arranged as:



```text

                    B RAM 0                 B RAM 1

                       |                       |

                       v                       v



A RAM 0 -------> +-------------+  B data  +-------------+ <------- A RAM 1

                 |   BLOCK 00  | --------> |   BLOCK 01  |

                 | a_loc = 0   |           | a_loc = 1   |

                 | b_loc = 0   |           | b_loc = 0   |

                 +------+------+           +------+------+

                        |                         |

                     A data                    A data

                        |                         |

                        v                         v

                 +-------------+  B data  +-------------+

                 |   BLOCK 10  | --------> |   BLOCK 11  |

                 | a_loc = 0   |           | a_loc = 1   |

                 | b_loc = 1   |           | b_loc = 1   |

                 +-------------+           +-------------+
