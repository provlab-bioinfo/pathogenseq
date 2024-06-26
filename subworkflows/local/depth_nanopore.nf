include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_DEPTH_NANOPORE } from '../../modules/local/minimap2/align/main'
include { SAMTOOLS_SORT as SAMTOOLS_SORT_DEPTH_NANOPORE } from '../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_DEPTH_NANOPORE } from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_COVERAGE as SAMTOOLS_COVERAGE_DEPTH_NANOPORE } from '../../modules/nf-core/samtools/coverage/main'
include { MAPPINGREPORT as MAPPINGREPORT_NANOPORE } from '../../modules/local/mappingreport'
workflow DEPTH_NANOPORE {   

    take:
        nanopore_reads
        contigs
    main:
        ch_versions = Channel.empty()
        
       /*  contigs.map{
            meta, contigs -> contigs
        }.set{ fasta } */
        
        nanopore_reads.map{
            meta, reads ->
                def new_meta = [:]
                new_meta.id = meta.id
                [ new_meta, meta, reads ] 

        }.set{
            ch_input_reads
        }
        contigs.map{
            meta, contigs ->
                def new_meta = [:]
                new_meta.id = meta.id
                [ new_meta, meta, contigs ] 
        }.set{
            ch_input_contigs
        }

        ch_input_reads.join(ch_input_contigs).multiMap{
            it ->
                reads: [it[1], it[2]]
                fasta_contigs: it[4]
        }.set{
            ch_input
        }
        /* nanopore_reads.join(contigs).multiMap{
            it ->
                reads: [it[0], it[1]]
                fasta_contigs: it[2]
        }.set{
            ch_input
        } */
        bam_format = true
        cigar_paf_format = false
        cigar_bam = false

        MINIMAP2_ALIGN_DEPTH_NANOPORE(ch_input.reads, ch_input.fasta_contigs, bam_format, cigar_paf_format, cigar_bam)
        ch_versions = ch_versions.mix(MINIMAP2_ALIGN_DEPTH_NANOPORE.out.versions.first())

        SAMTOOLS_SORT_DEPTH_NANOPORE(MINIMAP2_ALIGN_DEPTH_NANOPORE.out.bam)
        SAMTOOLS_INDEX_DEPTH_NANOPORE(SAMTOOLS_SORT_DEPTH_NANOPORE.out.bam)
        SAMTOOLS_COVERAGE_DEPTH_NANOPORE(SAMTOOLS_SORT_DEPTH_NANOPORE.out.bam.join(SAMTOOLS_INDEX_DEPTH_NANOPORE.out.bai))
        ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE_DEPTH_NANOPORE.out.versions.first())
        MAPPINGREPORT_NANOPORE(SAMTOOLS_COVERAGE_DEPTH_NANOPORE.out.coverage)

    emit:

        contig_coverage = SAMTOOLS_COVERAGE_DEPTH_NANOPORE.out.coverage
        sample_coverage = MAPPINGREPORT_NANOPORE.out.tsv
        versions = ch_versions
       

}
