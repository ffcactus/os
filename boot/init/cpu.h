#ifndef CPU_H
#define CPU_H

#define MAX_DESCRIPTORS (256)

#define GDT_ACCESS_VM_S		1
#define GDT_ACCESS_VM_C		0
#define GDT_ACCESS_RW_S		(1 << 1)
#define GDT_ACCESS_RW_C		(0 << 1)
#define GDT_ACCESS_EXP_CON_S	(1 << 2)
#define GDT_ACCESS_EXP_CON_C	(0 << 2)
#define GDT_ACCESS_EXEC
#define GDT_ACESS_CODE
#define GDT_ACESS_MEM

#define GDT_GRAND_4K
#define GDT_GRAND_32
#define GDT_LIMIT_HI_MASK

/**
 * The GDT descriptor.
 */
union gdt_desc {
	struct {
		uint64_t seg_limit_low : 16;
		uint64_t base_low : 16;
		uint64_t base_min : 8;
		uint64_t access_bit : 1;
		uint64_t rw : 1;
		uint64_t exec_seg : 1;
		uint64_t desc_bit : 1;
		uint64_t priv : 2;
		uint64_t seg_in_mem : 1;
		uint64_t seg_limit_high : 4;
		uint64_t reserved_os : 1;
		uint64_t reserved : 1;
		uint64_t seg_type : 1;
		uint64_t granularity : 1;
		uint64_t base_high : 9;
	} bit;
	struct {
		uint16_t limit;
		uint16_t base_low;
		uint8_t base_mid;
		uint8_t flags;
		uint8_t grand;
		uint8_t base_high;
	} group;

} __attribute__ ((packed));

/**
 * The GDT
 */
struct gdtr {
	uint16_t limit;
	uint32_t base;
} __attribute__ ((packed));

#endif
