
sample="SRR1518011"
sample_1="{sample}_1"
sample_2="{sample}_2"
reference="Homo_sapiens.GRCh38.dna.chromosome.10"
 
workdir: "/Data"
rule all:
    input:
        vcf="SRR1518011_variants_filtered.recode.vcf"


rule unzip:
    input:
        read1_fastq_zip="{sample}_1.fastq.gz",
        read2_fastq_zip="{sample}_2.fastq.gz"
    output:
        read1_fastq="{sample}_1.fastq",
        read2_fastq="{sample}_2.fastq"
    shell:
        "gzip -d {input}"

rule qc:
    input:
        file1="{sample}_1.fastq",
        file2="{sample}_2.fastq"
    output:
        read1_paired_trimed="{sample}_1_paired_trimmed.fastq",
        read1_unpaired_fasta_trimmed="{sample}_1_unpaired_trimmed.fastq",
        read2_paired_trimmed="{sample}_2_paired_trimmed.fastq",
        read2_unpaired_fasta_trimmed="{sample}_2_unpaired_trimmed.fastq",
    shell:
        "TrimmomaticPE -phred33 -threads 1 -trimlog {sample}_trimlog {input} {output} ILLUMINACLIP:/Data/primer_adapters.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36"

rule fasta_conversion:
    input:
        paired="{sample}_1_paired_trimmed.fastq"
    output:
        trimmed="{sample}_1_paired_trimmed.fasta"
    shell:
        "sed -n '1~4s/^@/>/p;2~4p' {input} > {output}"

rule st_indexing:
    input:
        ref="{reference}.fa"
    output:
        ref_idx="{reference}.fa.fai"
    shell:
        "samtools faidx {input}"

rule bwa_index:
    input:
        ref="{reference}.fa"
    output:
        ref_sa="{reference}.fa.sa"
    shell:
        "bwa index -a is {input}"


rule alignment:
    input:
        ref=f"{reference}.fa",
        lane1="{sample}_1_paired_trimmed.fastq",
        lane2="{sample}_2_paired_trimmed.fastq",
        ind=f'{reference}.fa.sa'
    output:
        bam="{sample}.bam"
    shell:
        "bwa mem -R '@RG\\tID:1\\tLB:library\\tPL:Illumina\\tPU:PlatUnit1\\tSM:{sample}' {input.ref} {input.lane1} {input.lane2} | samtools view -b - -o {output}"

rule remove_dups:
    input:
        bam="{sample}.bam"
    output:
        no_dup_bam="{sample}_no_dup.bam"
    shell:
        "samtools rmdup -S {input} {output}"

rule sort_bam:
    input:
        no_dup_bam="{sample}_no_dup.bam"
    output:
        sorted_bam="{sample}_no_dup_sorted.bam"
    shell:
        "samtools sort -o {output} {input}"

rule index_bam:
    input:
        sorted_bam="{sample}_no_dup_sorted.bam"
    output:
        index_bam="{sample}_no_dup_sorted.bam.bai"
    shell:
        "samtools index {input} {output}"

rule variant_call:
    input:
        ref="Homo_sapiens.GRCh38.dna.chromosome.10.fa",
        bam="{sample}_no_dup_sorted.bam"
    output:
        vcf="{sample}_variants_raw.vcf"
    shell:
     "freebayes -f {input.ref} -b {input.bam} -v {output}"
    
rule variant_filtering:
    input:
        vcf="{sample}_variants_raw.vcf"
    output:
        vcf_filtered ="{sample}_variants_filtered.recode.vcf"
    shell:
        "vcftools --vcf {input} --minDP 2 --minQ 20 --recode --recode-INFO-all --stdout | cat > {output.vcf_filtered}" 